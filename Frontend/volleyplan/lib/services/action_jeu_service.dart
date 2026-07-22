import 'api_service.dart';

class ActionJeuService {
  static Future<Map<String, dynamic>> getConfig() async {
    return await ApiService.get('/actions/config');
  }

  static Future<Map<String, dynamic>> enregistrerBatch(
      int seanceId, int exerciceId, List<Map<String, dynamic>> actions) async {
    return await ApiService.post(
      '/actions/seance/$seanceId/exercice/$exerciceId/actions',
      {'actions': actions},
    );
  }

  static Future<Map<String, dynamic>> getStatsJoueurExercice(
      int exerciceId, int joueurId) async {
    return await ApiService.get('/actions/exercice/$exerciceId/joueur/$joueurId/stats');
  }

  static Future<Map<String, dynamic>> getStatsExercice(int exerciceId) async {
    return await ApiService.get('/actions/exercice/$exerciceId/stats');
  }

  static Future<Map<String, dynamic>> getStatsSeance(int seanceId) async {
    return await ApiService.get('/actions/seance/$seanceId/stats');
  }
}