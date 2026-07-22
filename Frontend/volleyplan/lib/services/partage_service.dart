import 'api_service.dart';

class PartageService {
  static Future<Map<String, dynamic>> genererLien(int planningId) async {
    return await ApiService.post('/plannings/$planningId/partage', {});
  }

  static Future<Map<String, dynamic>> getLienActuel(int planningId) async {
    return await ApiService.get('/plannings/$planningId/partage');
  }

  static Future<Map<String, dynamic>> getPlanningPublic(String token) async {
    return await ApiService.get('/public/planning/$token');
  }
}