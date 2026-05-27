import 'api_service.dart';
import '../models/notification.dart';

class NotificationService {
  static Future<List<VpNotification>> getNotifications() async {
    final res = await ApiService.get('/notifications/list');
    final list = res['data'] is List ? res['data'] as List : [];
    return list.map((n) => VpNotification.fromJson(n)).toList();
  }

  static Future<void> markAsRead(int id) async {
    await ApiService.put('/notifications/read/$id', {});
  }
}
