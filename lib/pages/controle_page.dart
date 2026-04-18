import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ble_service.dart';
import '../widgets/carte_effet.dart';

class ControlePage extends StatefulWidget {
	final BleService ble;

	const ControlePage({super.key, required this.ble});

	@override
	State<ControlePage> createState() => _ControlePageState();
}

class _ControlePageState extends State<ControlePage> {
	late double _luminosite;
	bool _attenteExpiree = false;
	Timer? _timerAttente;

	@override
	void initState() {
		super.initState();
		_luminosite = widget.ble.luminosite.toDouble();
		widget.ble.addListener(_onBleChange);
		_demarrerAttenteEffets();
	}

	void _demarrerAttenteEffets() {
		_attenteExpiree = false;
		_timerAttente?.cancel();
		_timerAttente = Timer(const Duration(seconds: 5), () {
			if (mounted && widget.ble.effets.isEmpty) {
				setState(() => _attenteExpiree = true);
			}
		});
	}

	void _onBleChange() {
		if (!mounted) return;
		// Effets reçus → on annule le timer
		if (widget.ble.effets.isNotEmpty) {
			_timerAttente?.cancel();
		}
		setState(() {});
	}

	@override
	void dispose() {
		_timerAttente?.cancel();
		widget.ble.removeListener(_onBleChange);
		super.dispose();
	}

	Future<void> _deconnecterEtSortir() async {
		await widget.ble.deconnecter();
		if (mounted) Navigator.of(context).pop();
	}

	@override
	Widget build(BuildContext context) {
		final ble = widget.ble;

		return PopScope(
			// Empêche le bouton retour système : l'utilisateur doit déconnecter explicitement
			canPop: false,
			child: Scaffold(
				appBar: AppBar(
					title: const Text('DAFT PUNK'),
					automaticallyImplyLeading: false,
					actions: [
						IconButton(
							icon: const Icon(Icons.bluetooth_disabled, color: Color(0xFF00E5FF)),
							onPressed: _deconnecterEtSortir,
							tooltip: 'Déconnecter',
						),
					],
				),
				body: Column(
					children: [
						// ── Bandeau de reconnexion ─────────────────────────────────
						if (!ble.estConnecte) _buildBandeau(ble),

						// ── Contenu principal ──────────────────────────────────────
						Expanded(
							child: ListView(
								padding: const EdgeInsets.all(16),
								children: [
									_buildLuminosite(ble),
									const SizedBox(height: 16),
									_buildTitreSectionEffets(context),
									const SizedBox(height: 8),
									...ble.effets.map(
										(effet) => CarteEffet(
											key: ValueKey(effet.idx),
											effet: effet,
											estActif: ble.idxEffetActif == effet.idx,
											ble: ble,
										),
									),
									if (ble.effets.isEmpty && ble.estConnecte)
										Center(
											child: Padding(
												padding: const EdgeInsets.only(top: 40),
												child: _attenteExpiree
														? Column(
																children: [
																	const Text(
																		'Aucun effet reçu',
																		style: TextStyle(color: Colors.white24),
																	),
																	const SizedBox(height: 12),
																	OutlinedButton.icon(
																		onPressed: () {
																			_demarrerAttenteEffets();
																			ble.demanderEffets();
																		},
																		icon: const Icon(Icons.refresh),
																		label: const Text('Redemander'),
																	),
																],
															)
														: const Column(
																children: [
																	CircularProgressIndicator(
																		color: Color(0xFFBF00FF),
																	),
																	SizedBox(height: 16),
																	Text(
																		'Chargement...',
																		style: TextStyle(
																			color: Colors.white38,
																			fontSize: 13,
																		),
																	),
																],
															),
											),
										),
								],
							),
						),
					],
				),
			),
		);
	}

	// ── Widgets ─────────────────────────────────────────────────────────────

	Widget _buildBandeau(BleService ble) {
		final enCours =
				ble.etat == EtatBle.scan || ble.etat == EtatBle.connexion;

		return Container(
			color: const Color(0xFF1A0015),
			padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
			child: Row(
				children: [
					Icon(
						enCours ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
						color: enCours ? const Color(0xFFBF00FF) : Colors.white38,
						size: 18,
					),
					const SizedBox(width: 10),
					Expanded(
						child: Text(
							enCours ? 'Reconnexion...' : 'Connexion perdue',
							style: const TextStyle(color: Colors.white54, fontSize: 13),
						),
					),
					if (enCours)
						const SizedBox(
							width: 16,
							height: 16,
							child: CircularProgressIndicator(
								strokeWidth: 2,
								color: Color(0xFFBF00FF),
							),
						)
					else
						TextButton(
							onPressed: ble.scanner,
							style: TextButton.styleFrom(
								padding: const EdgeInsets.symmetric(horizontal: 12),
								minimumSize: Size.zero,
								tapTargetSize: MaterialTapTargetSize.shrinkWrap,
							),
							child: const Text(
								'Reconnecter',
								style: TextStyle(color: Color(0xFFBF00FF), fontSize: 13),
							),
						),
				],
			),
		);
	}

	Widget _buildLuminosite(BleService ble) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								const Icon(Icons.brightness_6, color: Color(0xFF00E5FF), size: 16),
								const SizedBox(width: 8),
								Text(
									'Luminosité  ${_luminosite.round()}',
									style: const TextStyle(
										color: Color(0xFF00E5FF),
										fontSize: 13,
									),
								),
							],
						),
						Slider(
							value: _luminosite,
							min: 0,
							max: 100,
							onChanged: (v) => setState(() => _luminosite = v),
							onChangeEnd: (v) => ble.setLuminosite(v.round()),
						),
					],
				),
			),
		);
	}

	Widget _buildTitreSectionEffets(BuildContext context) {
		return Text(
			'EFFETS',
			style: Theme.of(context).textTheme.labelSmall?.copyWith(
						letterSpacing: 4,
						color: const Color(0xFF6600AA),
					),
		);
	}
}
