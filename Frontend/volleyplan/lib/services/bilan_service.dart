// lib/services/bilan_service.dart
import 'api_service.dart';

class BilanService {
  static Future<Map<String, dynamic>> getBilan(int planningId) async {
    final res = await ApiService.get('/bilan/$planningId');
    return res; // Supposons que 'res' est déjà la carte que nous voulons
  }
}
