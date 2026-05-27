class VpNotification {
  final int id;
  final String message;
  final String createdAt;

  VpNotification(
      {required this.id, required this.message, required this.createdAt});

  factory VpNotification.fromJson(Map<String, dynamic> json) => VpNotification(
        id: json['id'],
        message: json['message'],
        createdAt: json['created_at'],
      );
}
