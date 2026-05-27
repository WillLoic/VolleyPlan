import 'api_service.dart';
import '../models/planning.dart';

class PlanningService {
  static Future<List<Planning>> getPlannings() async {
    final res = await ApiService.get('/plannings/list');
    return (res['data'] as List).map((p) => Planning.fromJson(p)).toList();
  }

  static Future<Planning> getPlanning(int id) async {
    final res = await ApiService.get('/plannings/$id');
    return Planning.fromJson(res);
  }

  static Future<Planning> getInvitePlanning(int id, String token) async {
    final res = await ApiService.get('/plannings/view_invite/$id/$token');
    return Planning.fromJson(res);
  }

  static Future<Planning> createPlanning(Map<String, dynamic> data) async {
    final res = await ApiService.post('/plannings/add_planning', data);
    return Planning.fromJson(res);
  }

  static Future<Planning> updatePlanning(
      int id, Map<String, dynamic> data) async {
    final res = await ApiService.put('/plannings/update_planning/$id', data);
    return Planning.fromJson(res);
  }

  static Future<Planning> updateInvitePlanning(
      int id, String token, Map<String, dynamic> data) async {
    final res =
        await ApiService.put('/plannings/update_invite/$id/$token', data);
    return Planning.fromJson(res);
  }

  static Future<void> deletePlanning(int id) async {
    await ApiService.delete('/plannings/delete_planning/$id');
  }

  static Future<Map<String, dynamic>> getBilan(int id, {String? token}) async {
    if (token != null) {
      return await ApiService.get('/bilan/token/$token');
    }
    return await ApiService.get('/bilan/$id');
  }

  static Future<List<int>> exportPdf(int id) async {
    return await ApiService.getBytes('/pdf/planning/$id');
  }

  static Future<Map<String, dynamic>> checkOverlap(
      Map<String, dynamic> data) async {
    return await ApiService.post('/plannings/check_overlap', data);
  }
}
