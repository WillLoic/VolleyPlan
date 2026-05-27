class Collaborator {
  final int? id;
  final int? coachId;
  final String email;
  final String status; // 'active' ou 'pending'

  Collaborator(
      {this.id, this.coachId, required this.email, this.status = 'active'});

  factory Collaborator.fromJson(Map<String, dynamic> json,
      {String status = 'active'}) {
    return Collaborator(
      id: json['id'],
      coachId: json['coach_id'],
      email: json['email'] ?? json['invited_email'],
      status: status,
    );
  }
}
