# Daft Punk LED Controller

Application mobile Flutter pour piloter un masque Daft Punk équipé d'une matrice LED WS2812B via Bluetooth BLE.

> Firmware ESP32 : [skankydev/Matrice-LED](https://github.com/skankydev/Matrice-LED)

---

## Matériel

| Composant | Détail |
|---|---|
| Microcontrôleur | ESP32-S3-N16R8 |
| LEDs | WS2812B flexible 32×8 (256 LEDs) |
| Communication | BLE uniquement |

---

## Effets disponibles

Rainbow · Text · Fire · Rain · Matrix · Fireworks · Scanner · Cylon · HeartBeat · Bounce · GameOfLife · PacmanGame · Sauron · Kawaii · VisorFire

---

## Stack

- **Flutter** + `universal_ble` + `flutter_colorpicker`
- Gestion d'état : `ChangeNotifier` (pas de riverpod)
- Android uniquement (non testé iOS)

---

## Fonctionnalités

- Scan BLE automatique et connexion au device **"Daft Punk"**
- Liste des effets chargée dynamiquement depuis l'ESP32
- Par effet : activation, slider de vitesse, color picker, champ texte (selon l'effet)
- Slider de luminosité global (0–100)
- Bandeau de reconnexion automatique si la connexion tombe
- Déconnexion propre à la fermeture de l'app

---

## Lancer le projet

```bash
flutter pub get
flutter run
```

Permissions BLE requises (Android 12+) : `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`  
Demandées automatiquement au premier scan.
