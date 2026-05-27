import 'api_service.dart';
import '../models/coach.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String nom,
    required String telephone,
    required String email,
    required String nomEquipe,
    required String password,
  }) async {
    final res = await ApiService.post('/auth/register', {
      'nom': nom,
      'telephone': telephone,
      'email': email,
      'nom_equipe': nomEquipe,
      'password': password,
    }, auth: false);
    await ApiService.saveToken(res['token']);
    return res;
  }

  static Future<Map<String, dynamic>> login({
    required String telephone,
    required String password,
  }) async {
    final res = await ApiService.post('/auth/login', {
      'telephone': telephone,
      'password': password,
    }, auth: false);
    await ApiService.saveToken(res['token']);
    return res;
  }

  static Future<Coach> getMe() async {
    final res = await ApiService.get('/auth/me');
    return Coach.fromJson(res);
  }

  static Future<void> logout() async {
    await ApiService.clearToken();
  }
}