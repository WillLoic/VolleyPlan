import 'joueur.dart';
import 'seance.dart';
import 'collaborator.dart';

class Planning {
  final int id;
  final int coachId;
  String titre;
  String mode;
  String duree;
  int nbSeances;
  String? poste;
  String? dateDebut;
  String? dateFin;
  List<Joueur> joueurs;
  List<Seance> seances;
  List<Collaborator> staff;
  List<Joueur> ownerRoster;
  final String createdAt;
  final String updatedAt;

  Planning({
    required this.id,
    required this.coachId,
    required this.titre,
    required this.mode,
    required this.duree,
    required this.nbSeances,
    this.poste,
    this.dateDebut,
    this.dateFin,
    this.joueurs = const [],
    this.seances = const [],
    this.staff = const [],
    this.ownerRoster = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Planning.fromJson(Map<String, dynamic> j) => Planning(
        id: j['id'],
        coachId: j['coach_id'],
        titre: j['titre'],
        mode: j['mode'],
        duree: j['duree'],
        nbSeances: j['nb_seances'],
        poste: j['poste'],
        dateDebut: j['date_debut'],
        dateFin: j['date_fin'],
        joueurs: (j['joueurs'] as List<dynamic>? ?? [])
            .map((x) => Joueur.fromJson(x))
            .toList(),
        seances: (j['seances'] as List<dynamic>? ?? [])
            .map((x) => Seance.fromJson(x))
            .toList(),
        staff: [
          ...(j['collaborators'] as List? ?? [])
              .map((c) => Collaborator.fromJson(c, status: 'active')),
          ...(j['invitations'] as List? ?? [])
              .map((i) => Collaborator.fromJson(i, status: 'pending')),
        ],
        ownerRoster: (j['owner_roster'] as List<dynamic>? ?? [])
            .map((x) => Joueur.fromJson(x))
            .toList(),
        createdAt: j['created_at'] ?? '',
        updatedAt: j['updated_at'] ?? '',
      );

  int get volumeTotal => seances.fold(0, (s, se) => s + se.dureeTotale);

  bool isOwner(int? currentCoachId) => coachId == currentCoachId;
}
