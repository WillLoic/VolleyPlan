import 'api_service.dart';

class AiService {
  /// Génère un planning d'entraînement via l'IA Gemini.
  ///
  /// [prompt]   : La demande textuelle du coach.
  /// [useStats] : Si true, l'IA analysera les statistiques de l'équipe.
  ///
  /// Retourne un Map contenant : titre, mode, nb_seances, seances[].
  /// Lance une [ApiException] en cas d'erreur (403 Premium, 503 indisponible…).
  static Future<Map<String, dynamic>> generatePlanning({
    required String prompt,
    required bool useStats,
    required String language,
  }) async {
    return await ApiService.post('/ai/planning/generate', {
      'prompt': prompt,
      'use_stats': useStats,
      'language': language,
    });
  }
}
