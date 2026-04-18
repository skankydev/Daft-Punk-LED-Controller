class Effet {
  final int idx;
  final String nom;
  int vitesse; // en ms (valeur réelle envoyée à l'ESP32)
  String? couleur; // hex sans '#', ex: "FF0000"
  String? texte;

  Effet({
    required this.idx,
    required this.nom,
    required this.vitesse,
    this.couleur,
    this.texte,
  });

  factory Effet.fromJson(Map<String, dynamic> json) => Effet(
        idx: json['idx'] as int,
        nom: json['name'] as String,
        vitesse: json['speed'] as int,
        couleur: (json['color'] as String?)?.replaceFirst('#', ''),
        texte: json['text'] as String?,
      );
}
