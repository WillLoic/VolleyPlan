class Exercice {
  int? id;
  int? seanceId;
  String nom;
  int duree;
  String domaine;
  String? description;
  int ordre;

  Exercice({
    this.id, this.seanceId,
    required this.nom, required this.duree, required this.domaine,
    this.description, this.ordre = 0,
  });

  factory Exercice.fromJson(Map<String, dynamic> j) => Exercice(
        id: j['id'],
        seanceId: j['seance_id'],
        nom: j['nom'],
        duree: j['duree'],
        domaine: j['domaine'],
        description: j['description'],
        ordre: j['ordre'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'duree': duree,
        'domaine': domaine,
        'description': description,
        'ordre': ordre,
      };
}