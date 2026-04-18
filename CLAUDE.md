# Daft Punk LED Controller

App Flutter qui pilote un masque Daft Punk via BLE. L'ESP32 contrôle une matrice WS2812B 32×8.

## Matériel
- ESP32 + matrice LEDs WS2812B 32×8
- Connexion BLE uniquement (pas de WiFi, pas de MQTT)
- Device BLE : **"Daft Punk"** (`58:BF:25:15:28:5E`)

## Protocole BLE
- **Service UUID** : `64dc919f-4c32-4b0d-a594-65334e0a72c3`
- **Caractéristique UUID** : `d21d93c2-18bd-402b-8614-b0ca683932ca` (READ + WRITE + NOTIFY)
- MTU négocié à 512 au connect (sinon les JSONs sont tronqués à 20 octets)

### Flow de connexion
1. Connect → `requestMtu(512)` → `discoverServices` → `subscribeNotifications`
2. Envoyer `getEffects`
3. Recevoir `{"count":N}` puis N JSONs d'effets individuels via NOTIFY

### Format d'un effet (JSON individuel)
```json
{"idx":6,"name":"Text","speed":80,"color":"#FF0000","text":"Daft Punk"}
```
- `color` et `text` sont optionnels

### Commandes WRITE (format `commande:valeur`)
```
getEffects                              → demande la liste des effets
setEffectFull:6|80|FF0000|Daft Punk    → effet + speed + color + text
setEffectFull:1|30|FF5000              → effet + speed + color
setEffectFull:0|50                     → effet + speed seulement
setBrightness:10                       → luminosité 0-100 (défaut 10)
```

## Stack Flutter
- `universal_ble: any` — BLE (gratuit, MIT). Pas flutter_blue_plus (payant)
- `flutter_colorpicker: ^1.1.0` — color picker (HueRingPicker)
- Gestion d'état : `ChangeNotifier` simple, pas de riverpod/provider
- Navigation : `Navigator.push` classique (ScanPage → ControlePage)

## Architecture
```
lib/
  main.dart                  ← MaterialApp, thème synthwave
  modeles/
    effet.dart               ← class Effet (mutable : vitesse, couleur, texte)
  services/
    ble_service.dart         ← BleService (ChangeNotifier), toute la logique BLE
  pages/
    scan_page.dart           ← scan auto "Daft Punk", protection double-push
    controle_page.dart       ← liste effets + slider luminosité + bandeau reconnexion
  widgets/
    carte_effet.dart         ← carte expansible : nom (toggle) + play (bouton droit)
```

## Thème
Synthwave dark — violet `#BF00FF` / cyan `#00E5FF` / fond `#0A0015`

## UX — points clés
- **Play** envoie `setEffectFull` avec les valeurs locales (effet + couleur + vitesse + texte)
- **Slider vitesse** : 0 (gauche) = 300ms lent → 300 (droite) = 0ms rapide. Valeur envoyée = `300 - sliderPosition`
- **Slider luminosité** : 0–100, défaut 10, envoi immédiat au relâché (`onChangeEnd`)
- **Couleur** : modifiée localement dans la carte, envoyée au play
- **Texte** : modifié localement dans la carte (`onChanged`), envoyé au play
- **Bandeau reconnexion** : affiché sur ControlePage si connexion perdue, bouton "Reconnecter" relance le scan
- **Liste vide** : spinner 5s → si toujours vide → "Aucun effet reçu" + bouton "Redemander"
- `PopScope(canPop: false)` sur ControlePage — retour uniquement via bouton déconnexion

## Points d'attention
- `universal_ble` utilise des callbacks statiques globaux (`UniversalBle.onScanResult = ...`) — un seul `BleService` actif à la fois
- `ScanPage` possède le `BleService` et ne le dispose qu'à la fermeture de l'app
- `WidgetsBindingObserver` dans `ScanPage` → déconnexion BLE sur `AppLifecycleState.detached`
- Les `debugPrint('[BLE] ...')` dans `ble_service.dart` sont à supprimer en prod
