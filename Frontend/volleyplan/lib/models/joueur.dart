class Joueur {
  final int id;
  final int coachId;
  final String nom;
  final String? poste;
  final bool actif;

  Joueur({required this.id, required this.coachId, required this.nom, this.poste, required this.actif});

  factory Joueur.fromJson(Map<String, dynamic> j) => Joueur(
        id: j['id'],
        coachId: j['coach_id'],
        nom: j['nom'],
        poste: j['poste'],
        actif: j['actif'] ?? true,
      );

  Map<String, dynamic> toJson() => {'nom': nom, 'poste': poste};
}