import 'package:flutter/material.dart';

import '../services/ble_service.dart';
import 'controle_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  final _ble = BleService();
  bool _enNavigation = false; // Protège contre le double-push

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ble.addListener(_onBleChange);
  }

  void _onBleChange() {
    if (!mounted) return;

    if (_ble.etat == EtatBle.connecte && !_enNavigation) {
      _enNavigation = true;
      Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (_) => ControlePage(ble: _ble),
          ))
          .then((_) => _enNavigation = false);
      return;
    }

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _ble.deconnecter();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ble.removeListener(_onBleChange);
    _ble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etat = _ble.etat;
    final enCours = etat == EtatBle.scan || etat == EtatBle.connexion;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ──────────────────────────────────────────────────
                const Icon(
                  Icons.headset,
                  size: 72,
                  color: Color(0xFFBF00FF),
                ),
                const SizedBox(height: 20),
                const Text(
                  'DAFT PUNK',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                    color: Color(0xFFBF00FF),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'LED CONTROLLER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 6,
                    color: Color(0xFF00E5FF),
                  ),
                ),

                const SizedBox(height: 60),

                // ── Statut ────────────────────────────────────────────────
                if (enCours) ...[
                  const CircularProgressIndicator(color: Color(0xFFBF00FF)),
                  const SizedBox(height: 20),
                  Text(
                    etat == EtatBle.scan
                        ? 'Recherche de "$kNomAppareil"...'
                        : 'Connexion en cours...',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  // Message d'erreur
                  if (etat == EtatBle.erreur && _ble.erreur != null) ...[
                    Text(
                      _ble.erreur!,
                      style: const TextStyle(
                        color: Color(0xFFBF00FF),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bouton scan
                  ElevatedButton.icon(
                    onPressed: _ble.scanner,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('SCANNER'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
