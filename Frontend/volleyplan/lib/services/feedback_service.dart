import 'api_service.dart';

class FeedbackService {
  static Future<void> sendFeedback(String commentaire) async {
    await ApiService.post('/feedbacks/add_feedbacks', {'commentaire': commentaire});
  }
}
