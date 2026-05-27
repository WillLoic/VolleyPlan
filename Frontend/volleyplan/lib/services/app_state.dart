import 'package:flutter/material.dart';
import '../models/coach.dart';
import '../models/joueur.dart';
import '../models/planning.dart';
import 'auth_service.dart';
import 'joueur_service.dart';
import 'planning_service.dart';
import 'invitation_service.dart';
import 'notification_service.dart';
import 'api_service.dart';
import '../models/notification.dart';

class AppState extends ChangeNotifier {
  Coach? coach;
  List<Joueur> joueurs = [];
  List<Planning> plannings = [];
  List<VpNotification> notifications = [];
  bool loading = false;
  Map<String, dynamic>? globalBilan;
  bool isInitialized = false; // Pour savoir si le démarrage est terminé
  String? error;

  bool get isLoggedIn => coach != null;

  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    error = e;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  // ── Auth ─────────────────────────────────────────────────────────
  Future<bool> tryAutoLogin() async {
    final token = await ApiService.getToken();
    if (token == null) {
      isInitialized = true;
      notifyListeners();
      return false;
    }

    try {
      coach = await AuthService.getMe();
      // On charge tout en parallèle
      await Future.wait([loadJoueurs(), loadPlannings(), loadNotifications()]);
      isInitialized = true;
      notifyListeners();
      return true;
    } catch (_) {
      await ApiService.clearToken();
      coach = null;
      joueurs = [];
      plannings = [];
      isInitialized = true;
      notifyListeners(); // Notifier les écouteurs de l'état effacé
      return false;
    }
  }

  Future<void> loadNotifications() async {
    try {
      notifications = await NotificationService.getNotifications();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> dismissNotification(int id) async {
    await NotificationService.markAsRead(id);
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> login(String telephone, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final res =
          await AuthService.login(telephone: telephone, password: password);
      if (res['coach'] != null) {
        coach = Coach.fromJson(res['coach']);
        await loadJoueurs();
        await loadPlannings();
      } else {
        throw Exception("Données du coach manquantes dans la réponse");
      }
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(
      String nom, String tel, String email, String equipe, String pwd) async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await AuthService.register(
          nom: nom,
          telephone: tel,
          email: email,
          nomEquipe: equipe,
          password: pwd);
      if (res['coach'] != null) {
        coach = Coach.fromJson(res['coach']);
        await loadJoueurs();
        await loadPlannings();
      } else {
        throw Exception(
            "Erreur lors de la création du compte : données manquantes");
      }
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    coach = null;
    joueurs = [];
    plannings = [];
    isInitialized = true;
    notifyListeners();
  }

  // ── Password Reset ─────────────────────────────────────────────
  Future<void> requestPasswordReset(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      // On utilise directement ApiService si AuthService n'est pas encore prêt
      await ApiService.post('/auth/forgot-password', {'email': email});
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      await ApiService.post(
          '/auth/reset-password', {'token': token, 'password': newPassword});
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadGlobalBilan() async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/bilan/global');
      globalBilan = res;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── Joueurs ──────────────────────────────────────────────────────
  Future<void> loadJoueurs({bool includeInactifs = false}) async {
    _setLoading(true);
    try {
      joueurs =
          await JoueurService.getJoueurs(includeInactifs: includeInactifs);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow; // Relancer l'exception pour que tryAutoLogin puisse la capturer
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addJoueur(String nom, {String? poste}) async {
    final j = await JoueurService.addJoueur(nom, poste: poste);
    joueurs.add(j);
    notifyListeners();
  }

  Future<void> updateJoueur(int id, Map<String, dynamic> data) async {
    final j = await JoueurService.updateJoueur(id, data);
    final idx = joueurs.indexWhere((x) => x.id == id);
    if (idx >= 0) joueurs[idx] = j;
    notifyListeners();
  }

  Future<void> removeJoueur(int id) async {
    await JoueurService.deleteJoueur(id);
    joueurs.removeWhere((j) => j.id == id);
    notifyListeners();
  }

  // ── Plannings ────────────────────────────────────────────────────
  Future<void> loadPlannings() async {
    _setLoading(true);
    try {
      plannings = await PlanningService.getPlannings();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow; // Relancer l'exception pour que tryAutoLogin puisse la capturer
    } finally {
      _setLoading(false);
    }
  }

  Future<Planning> loadPlanning(int id, {String? token}) async {
    final p = token != null
        ? await PlanningService.getInvitePlanning(id, token)
        : await PlanningService.getPlanning(id);
    final idx = plannings.indexWhere((x) => x.id == id);
    if (idx >= 0)
      plannings[idx] = p;
    else
      plannings.insert(0, p);

    // Si c'est un planning partagé, on peuple la liste globale joueurs avec le roster du proprio
    if (token != null || p.coachId != coach?.id) {
      joueurs = p.ownerRoster;
    }

    notifyListeners();
    return p;
  }

  Future<Planning> createPlanning(Map<String, dynamic> data) async {
    final p = await PlanningService.createPlanning(data);
    plannings.insert(0, p);
    notifyListeners();
    return p;
  }

  Future<Planning> updatePlanning(int id, Map<String, dynamic> data,
      {String? token}) async {
    final p = token != null
        ? await PlanningService.updateInvitePlanning(id, token, data)
        : await PlanningService.updatePlanning(id, data);
    final idx = plannings.indexWhere((x) => x.id == id);
    if (idx >= 0) plannings[idx] = p;
    notifyListeners();
    return p;
  }

  Future<void> deletePlanning(int id) async {
    await PlanningService.deletePlanning(id);
    plannings.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ── Collaboration ──────────────────────────────────────────────
  Future<void> inviteCollaborator(int planningId, String email) async {
    _setLoading(true);
    try {
      await InvitationService.sendInvitation(planningId, email);
      // On rafraîchit le planning pour voir l'invitation dans la liste "Staff"
      await loadPlanning(planningId);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeCollaborator(int planningId, String email) async {
    _setLoading(true);
    try {
      await InvitationService.removeCollaborator(planningId, email);
      await loadPlanning(
          planningId); // Rafraîchissement pour refléter le retrait
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptInvitation(String token) async {
    _setLoading(true);
    try {
      await InvitationService.acceptInvitation(token, coachId: coach?.id);
      if (isLoggedIn) await loadPlannings();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
