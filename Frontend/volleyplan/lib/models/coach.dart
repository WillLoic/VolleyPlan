class Coach {
  final int id;
  final String nom;
  final String telephone;
  final String nomEquipe;
  final String email;
  final String role;

  Coach({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.nomEquipe,
    required this.email,
    required this.role,
  });

  factory Coach.fromJson(Map<String, dynamic> j) => Coach(
        id: j['id'],
        nom: j['nom'],
        telephone: j['telephone'],
        nomEquipe: j['nom_equipe'],
        email: j['email'] ?? '',
        role: j['role'] ?? 'user',
      );
}
