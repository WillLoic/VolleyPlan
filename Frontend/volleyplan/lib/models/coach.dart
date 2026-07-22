class Coach {
  final int id;
  final String nom;
  final String telephone;
  final String nomEquipe;
  final String email;
  final String role;
  final String forfait;

  Coach({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.nomEquipe,
    required this.email,
    required this.role,
    required this.forfait,
  });

  bool get isPremium => forfait.toUpperCase() == 'PREMIUM';

  factory Coach.fromJson(Map<String, dynamic> j) => Coach(
        id: j['id'],
        nom: j['nom'],
        telephone: j['telephone'],
        nomEquipe: j['nom_equipe'],
        email: j['email'] ?? '',
        role: j['role'] ?? 'user',
        forfait: (j['forfait'] ?? 'FREE').toString(),
      );
}
