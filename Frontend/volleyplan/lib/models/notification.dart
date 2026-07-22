/*class VpNotification {
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

class VpNotification {
  final int id;
  final String message;
  final bool isRead;
  final String type;
  final int? seanceId;
  final String createdAt;

  VpNotification({
    required this.id,
    required this.message,
    required this.isRead,
    required this.type,
    this.seanceId,
    required this.createdAt,
  });

  factory VpNotification.fromJson(Map<String, dynamic> json) => VpNotification(
        id: json['id'],
        message: json['message'],
        isRead: json['is_read'] ?? false,
        type: json['type'] ?? 'general',
        seanceId: json['seance_id'],
        createdAt: json['created_at'],
      );

  bool get isPresenceRappel => type == 'presence_rappel';
}
 */

class VpNotification {
  final int id;
  final String message;
  final bool isRead;
  final String type;
  final int? seanceId;
  final String createdAt;

  VpNotification({
    required this.id,
    required this.message,
    required this.isRead,
    required this.type,
    this.seanceId,
    required this.createdAt,
  });

  factory VpNotification.fromJson(Map<String, dynamic> json) => VpNotification(
        id: json['id'],
        message: json['message'],
        isRead: json['is_read'] ?? false,
        type: json['type'] ?? 'general',
        seanceId: json['seance_id'],
        createdAt: json['created_at'],
      );

  bool get isPresenceRappel => type == 'presence_rappel';
}