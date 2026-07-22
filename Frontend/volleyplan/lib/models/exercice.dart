class Exercice {
  int? id;
  int? seanceId;
  String nom;
  int duree;
  List<String> domaines; // Liste de domaines (ex: ["service", "reception"])
  String? description;
  int ordre;

  Exercice({
    this.id, this.seanceId,
    required this.nom, required this.duree, required this.domaines,
    this.description, this.ordre = 0,
  });

  factory Exercice.fromJson(Map<String, dynamic> j) {
    // Rétrocompatibilité : si le backend renvoie encore "domaine" (string)
    List<String> domaines;
    if (j['domaines'] != null) {
      domaines = List<String>.from(j['domaines']);
    } else if (j['domaine'] != null) {
      domaines = [j['domaine'] as String];
    } else {
      domaines = [];
    }
    return Exercice(
      id: j['id'],
      seanceId: j['seance_id'],
      nom: j['nom'],
      duree: j['duree'],
      domaines: domaines,
      description: j['description'],
      ordre: j['ordre'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'nom': nom,
      'duree': duree,
      'domaines': domaines,
      'description': description,
      'ordre': ordre,
    };
    if (id != null) data['id'] = id;
    return data;
  }
}