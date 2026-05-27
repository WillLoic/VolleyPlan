// lib/services/invitation_service.dart
import 'api_service.dart';
import '../models/planning.dart';

class InvitationService {
  static Future<void> sendInvitation(int planningId, String email) async {
    await ApiService.post('/invitations/send', {
      'planning_id': planningId,
      'email': email,
    });
  }

  static Future<Map<String, dynamic>> validateToken(String token) async {
    return await ApiService.get('/invitations/validate/$token');
  }

  static Future<Planning> getPlanningByToken(String token) async {
    final res = await ApiService.get('/invitations/view_planning/$token');
    return Planning.fromJson(res);
  }

  static Future<void> acceptInvitation(String token, {int? coachId}) async {
    await ApiService.post('/invitations/accept', {
      'token': token,
      if (coachId != null) 'coach_id': coachId,
    });
  }

  static Future<void> removeCollaborator(int planningId, String email) async {
    await ApiService.delete(
        '/invitations/planning/$planningId/collaborators/$email');
  }
}
