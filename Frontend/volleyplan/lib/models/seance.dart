import 'exercice.dart';

class Seance {
  int? id;
  int? planningId;
  String titre;
  int ordre;
  List<String> domaines;
  String? dateSeance;
  String? heureDebut;
  String? lieu;
  String? notes;
  int dureeTotal;
  List<Exercice> exercices;

  Seance({
    this.id, this.planningId,
    required this.titre, this.ordre = 0,
    this.domaines = const [],
    this.dateSeance, this.heureDebut, this.lieu, this.notes,
    this.dureeTotal = 0,
    this.exercices = const [],
  });

  factory Seance.fromJson(Map<String, dynamic> j) => Seance(
        id: j['id'],
        planningId: j['planning_id'],
        titre: j['titre'],
        ordre: j['ordre'] ?? 0,
        domaines: List<String>.from(j['domaines'] ?? []),
        dateSeance: j['date_seance'],
        heureDebut: j['heure_debut'],
        lieu: j['lieu'],
        notes: j['notes'],
        dureeTotal: j['duree_totale'] ?? 0,
        exercices: (j['exercices'] as List<dynamic>? ?? [])
            .map((e) => Exercice.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'ordre': ordre,
        'domaines': domaines,
        'date_seance': dateSeance,
        'heure_debut': heureDebut,
        'lieu': lieu,
        'notes': notes,
        'exercices': exercices.map((e) => e.toJson()).toList(),
      };

  int get dureeTotale => exercices.fold(0, (s, e) => s + e.duree);
}