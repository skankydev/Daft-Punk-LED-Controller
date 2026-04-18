import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import '../modeles/effet.dart';

const kServiceUuid = '64dc919f-4c32-4b0d-a594-65334e0a72c3';
const kCaracUuid = 'd21d93c2-18bd-402b-8614-b0ca683932ca';
const kNomAppareil = 'Daft Punk';

enum EtatBle { deconnecte, scan, connexion, connecte, erreur }

class BleService extends ChangeNotifier {
  EtatBle _etat = EtatBle.deconnecte;
  List<Effet> _effets = [];
  int? _idxEffetActif;
  int _luminosite = 10;
  String? _erreur;
  String? _deviceId;
  Timer? _timerScan;

  // Réception des effets en plusieurs notifications
  int? _effetsAttendus;
  final List<Effet> _effetsEnCours = [];

  // ── Getters ───────────────────────────────────────────────────────────────

  EtatBle get etat => _etat;
  List<Effet> get effets => _effets;
  int? get idxEffetActif => _idxEffetActif;
  int get luminosite => _luminosite;
  String? get erreur => _erreur;
  bool get estConnecte => _etat == EtatBle.connecte;

  // ── Constructeur ──────────────────────────────────────────────────────────

  BleService() {
    UniversalBle.onScanResult = _onScanResult;
    UniversalBle.onConnectionChange = _onConnexionChange;
    UniversalBle.onValueChange = _onValeurChange;
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<void> scanner() async {
    _erreur = null;
    _timerScan?.cancel();
    _setEtat(EtatBle.scan);

    try {
      await UniversalBle.requestPermissions();
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withNamePrefix: [kNomAppareil]),
      );
      // Timeout manuel : universal_ble ne gère pas ça nativement
      _timerScan = Timer(const Duration(seconds: 15), () {
        if (_etat == EtatBle.scan) {
          _stopperScan();
          _erreur = '"$kNomAppareil" introuvable';
          _setEtat(EtatBle.erreur);
        }
      });
    } catch (e) {
      _erreur = e.toString();
      _setEtat(EtatBle.erreur);
    }
  }

  void _onScanResult(BleDevice device) async {
    if (_etat != EtatBle.scan) return;
    if (device.name != kNomAppareil) return;

    _timerScan?.cancel();
    _deviceId = device.deviceId;
    _setEtat(EtatBle.connexion); // Protège contre les doublons de callback

    await _stopperScan();

    try {
      await UniversalBle.connect(_deviceId!);
    } catch (e) {
      _erreur = e.toString();
      _setEtat(EtatBle.erreur);
    }
  }

  Future<void> _stopperScan() async {
    try {
      await UniversalBle.stopScan();
    } catch (_) {}
  }

  // ── Connexion ─────────────────────────────────────────────────────────────

  void _onConnexionChange(
    String deviceId,
    bool isConnected,
    String? error,
  ) async {
    if (_deviceId == null || deviceId != _deviceId) return;

    if (!isConnected) {
      _effets = [];
      _idxEffetActif = null;
      _setEtat(EtatBle.deconnecte);
      return;
    }

    // Connecté → découverte des services, souscription, puis demande de la liste
    try {
      await UniversalBle.requestMtu(_deviceId!, 512);
      await UniversalBle.discoverServices(_deviceId!);
      await UniversalBle.subscribeNotifications(_deviceId!, kServiceUuid, kCaracUuid);
      _setEtat(EtatBle.connecte);
      await _envoyer('getEffects');
    } catch (e) {
      _erreur = e.toString();
      _setEtat(EtatBle.erreur);
    }
  }

  Future<void> deconnecter() async {
    if (_deviceId == null) return;
    _timerScan?.cancel();
    final id = _deviceId!;
    _deviceId = null; // Neutralise les callbacks entrants
    _effets = [];
    _idxEffetActif = null;
    _setEtat(EtatBle.deconnecte);
    try {
      await UniversalBle.disconnect(id);
    } catch (_) {}
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  void _onValeurChange(
    String deviceId,
    String characteristicId,
    Uint8List value,
    int? timestamp,
  ) {
    debugPrint('[BLE] onValueChange — device: $deviceId / carac: $characteristicId');
    debugPrint('[BLE] raw: ${utf8.decode(value, allowMalformed: true)}');
    if (_deviceId == null || deviceId != _deviceId) return;
    _traiterNotification(value);
  }

  void _traiterNotification(Uint8List data) {
    try {
      final texte = utf8.decode(data);
      final obj = jsonDecode(texte) as Map<String, dynamic>;

      if (obj.containsKey('count')) {
        _effetsAttendus = obj['count'] as int;
        _effetsEnCours.clear();
        debugPrint('[BLE] count reçu: $_effetsAttendus effets attendus');
      } else if (obj.containsKey('idx')) {
        _effetsEnCours.add(Effet.fromJson(obj));
        debugPrint('[BLE] effet reçu: ${obj['name']} (${_effetsEnCours.length}/$_effetsAttendus)');
        if (_effetsAttendus != null &&
            _effetsEnCours.length >= _effetsAttendus!) {
          _effets = List.from(_effetsEnCours);
          _effetsAttendus = null;
          _effetsEnCours.clear();
          debugPrint('[BLE] liste complète : ${_effets.length} effets');
          notifyListeners();
        }
      } else {
        debugPrint('[BLE] notification inconnue: $texte');
      }
    } catch (e) {
      debugPrint('[BLE] erreur parsing: $e');
    }
  }

  /// Redemande la liste des effets à l'ESP32
  Future<void> demanderEffets() async => _envoyer('getEffects');

  // ── Commandes BLE ─────────────────────────────────────────────────────────

  Future<void> _envoyer(String commande) async {
    if (_deviceId == null || !estConnecte) return;
    await UniversalBle.write(
      _deviceId!,
      kServiceUuid,
      kCaracUuid,
      Uint8List.fromList(utf8.encode(commande)),
    );
  }

  /// Appui sur play : envoie tout en une seule commande setEffectFull
  Future<void> activerEffet(Effet effet) async {
    final buf = StringBuffer('setEffectFull:${effet.idx}|${effet.vitesse}');
    if (effet.couleur != null) {
      buf.write('|${effet.couleur}');
      if (effet.texte != null && effet.texte!.isNotEmpty) {
        buf.write('|${effet.texte}');
      }
    }
    await _envoyer(buf.toString());
    _idxEffetActif = effet.idx;
    notifyListeners();
  }

  /// Slider luminosité global — envoi immédiat au relâché
  Future<void> setLuminosite(int valeur) async {
    _luminosite = valeur;
    await _envoyer('setBrightness:$valeur');
    notifyListeners();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void _setEtat(EtatBle etat) {
    _etat = etat;
    notifyListeners();
  }

  @override
  void dispose() {
    _timerScan?.cancel();
    UniversalBle.onScanResult = null;
    UniversalBle.onConnectionChange = null;
    UniversalBle.onValueChange = null;
    super.dispose();
  }
}
