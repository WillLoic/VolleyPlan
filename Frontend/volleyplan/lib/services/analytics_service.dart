import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AnalyticsService {
  static String? _sessionId;

  /// Initialise une nouvelle session avec un ID unique au lancement de l'app
  static void initSession() {
    final random = Random();
    _sessionId =
        '${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(10000)}';
  }

  /// Envoie un événement au serveur de manière asynchrone (non-bloquant)
  static void trackEvent(String eventName,
      {Map<String, dynamic>? data, String? token}) {
    final url = Uri.parse('${AppConstants.baseUrl}/admin/analytics/event');

    try {
      // On utilise .then pour ne pas bloquer l'UI (Fire and Forget)
      http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'event_name': eventName,
          'event_data': data,
          'session_id': _sessionId,
        }),
      )
          .then((response) {
        if (response.statusCode != 201) {
          debugPrint('Analytics Error: ${response.statusCode}');
        }
      });
    } catch (e) {
      debugPrint('Analytics Network Error: $e');
    }
  }
}

/// Petit helper interne pour le debug
void debugPrint(String msg) {
  print(msg);
}
