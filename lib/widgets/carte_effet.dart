import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../modeles/effet.dart';
import '../services/ble_service.dart';

class CarteEffet extends StatefulWidget {
  final Effet effet;
  final bool estActif;
  final BleService ble;

  const CarteEffet({
    super.key,
    required this.effet,
    required this.estActif,
    required this.ble,
  });

  @override
  State<CarteEffet> createState() => _CarteEffetState();
}

class _CarteEffetState extends State<CarteEffet> {
  bool _ouvert = false;

  // Slider vitesse : 0 = lent (300ms), 300 = rapide (0ms)
  // valeur envoyée = 300 - _vitesse
  late double _vitesse;

  late TextEditingController _texteCtrl;

  @override
  void initState() {
    super.initState();
    _vitesse = (300 - widget.effet.vitesse).clamp(0.0, 300.0).toDouble();
    _texteCtrl = TextEditingController(text: widget.effet.texte ?? '');
  }

  @override
  void didUpdateWidget(covariant CarteEffet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mise à jour si le JSON a changé (reconnexion, notification BLE)
    final nouvelleVitesse =
        (300 - widget.effet.vitesse).clamp(0.0, 300.0).toDouble();
    if ((nouvelleVitesse - _vitesse).abs() > 1) _vitesse = nouvelleVitesse;

    if (widget.effet.texte != null &&
        widget.effet.texte != _texteCtrl.text) {
      _texteCtrl.text = widget.effet.texte!;
    }
  }

  @override
  void dispose() {
    _texteCtrl.dispose();
    super.dispose();
  }

  // ── Couleur ────────────────────────────────────────────────────────────────

  Color _couleurDepuisHex(String hex) =>
      Color(int.parse('FF$hex', radix: 16));

  String _hexDepuisCouleur(Color c) {
    return c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  Future<void> _ouvrirColorPicker() async {
    final couleurInitiale = widget.effet.couleur != null
        ? _couleurDepuisHex(widget.effet.couleur!)
        : const Color(0xFFFFFFFF);

    Color selection = couleurInitiale;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF150025),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A0050)),
          ),
          title: const Text(
            'Couleur',
            style: TextStyle(color: Color(0xFFBF00FF), letterSpacing: 2),
          ),
          content: SizedBox(
            width: 280,
            child: HueRingPicker(
              pickerColor: selection,
              onColorChanged: (c) {
                setDialogState(() => selection = c);
              },
              enableAlpha: false,
              displayThumbColor: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final hex = _hexDepuisCouleur(selection);
                setState(() => widget.effet.couleur = hex);
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final effet = widget.effet;
    final estActif = widget.estActif;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estActif ? const Color(0xFFBF00FF) : const Color(0xFF2A0050),
          width: estActif ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Header : nom + play ────────────────────────────────────────
          Row(
            children: [
              // Nom — tap pour ouvrir/fermer le formulaire
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  onTap: () => setState(() => _ouvert = !_ouvert),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            effet.nom,
                            style: TextStyle(
                              color: estActif
                                  ? const Color(0xFFBF00FF)
                                  : Colors.white,
                              fontWeight: estActif
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _ouvert ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Play
              IconButton(
                icon: Icon(
                  estActif ? Icons.play_circle : Icons.play_circle_outline,
                  size: 30,
                  color: estActif
                      ? const Color(0xFFBF00FF)
                      : const Color(0xFF00E5FF),
                ),
                onPressed: () => widget.ble.activerEffet(effet),
                tooltip: 'Activer',
              ),
            ],
          ),

          // ── Formulaire expansible ──────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _ouvert ? _buildFormulaire(effet) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaire(Effet effet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFF2A0050), height: 1),
          const SizedBox(height: 12),

          // ── Vitesse ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vitesse',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              Text(
                '${(300 - _vitesse).round()} ms',
                style: const TextStyle(
                    color: Color(0xFF00E5FF), fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: _vitesse,
            min: 0,
            max: 300,
            onChanged: (v) => setState(() => _vitesse = v),
            onChangeEnd: (v) => effet.vitesse = (300 - v).round(),
          ),

          // ── Couleur ───────────────────────────────────────────────────
          if (effet.couleur != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _couleurDepuisHex(effet.couleur!),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _ouvrirColorPicker,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Choisir la couleur'),
                ),
              ],
            ),
          ],

          // ── Texte ─────────────────────────────────────────────────────
          if (effet.texte != null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _texteCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (v) => effet.texte = v,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Texte affiché',
                labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2A0050)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFBF00FF)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
