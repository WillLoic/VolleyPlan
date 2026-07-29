import 'package:flutter/material.dart';
import '../models/coach.dart';
import '../models/joueur.dart';
import '../models/planning.dart';
import 'auth_service.dart';
import 'joueur_service.dart';
import 'planning_service.dart';
import 'invitation_service.dart';
import 'notification_service.dart';
import 'feedback_service.dart';
import 'api_service.dart';
import '../models/notification.dart';
import 'analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  Coach? coach;
  List<Joueur> joueurs = [];
  List<Planning> plannings = [];
  List<VpNotification> notifications = [];
  String? _token;
  bool loading = false;

  /// Set to true just after a successful registration to allow a special
  /// redirect flow (register -> /tarifs -> /home) without being auto-redirected
  /// immediately to `/home` by the router.
  bool justRegistered = false;
  Map<String, dynamic>? globalBilan;
  bool isInitialized = false; // Pour savoir si le démarrage est terminé
  String? error;

  // Données Admin
  Map<String, dynamic>? adminSummary;
  List<dynamic> adminCoaches = [];
  List<dynamic> adminFeedbacks = [];

  // Gestion de la langue
  Locale _currentLocale = const Locale('fr'); // Locale par défaut

  bool get isLoggedIn => coach != null;
  String? get token => _token;
  Locale get currentLocale => _currentLocale;

  // Change la langue et la sauvegarde localement
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  // Charge la langue sauvegardée au démarrage
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code');
    if (code != null) {
      _currentLocale = Locale(code);
      notifyListeners();
    }
  }

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
      _token = token;
      // Charger la langue et le profil en parallèle
      await Future.wait(
          [loadSavedLocale(), AuthService.getMe().then((c) => coach = c)]);

      // On charge tout en parallèle
      await Future.wait([loadJoueurs(), loadPlannings(), loadNotifications()]);
      isInitialized = true;
      notifyListeners();
      return true;
    } catch (_) {
      await ApiService.clearToken();
      _token = null;
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

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await AuthService.login(email: email, password: password);
      if (res['coach'] != null) {
        _token = res['token'];
        coach = Coach.fromJson(res['coach']);
        AnalyticsService.trackEvent('login', token: _token);
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
        _token = res['token'];
        coach = Coach.fromJson(res['coach']);
        AnalyticsService.trackEvent('register', token: _token);
        await loadJoueurs();
        await loadPlannings();
        // Mark that the user has just registered so the router can allow
        // showing the tarifs page before redirecting to home.
        justRegistered = true;
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

  /// Clear the just-registered flag.
  void clearJustRegistered() {
    if (!justRegistered) return;
    justRegistered = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.logout();
    _token = null;
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
      AnalyticsService.trackEvent('password_reset_requested',
          data: {'email': email});
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

  Future<void> updateProfile(String email, String nom, String tel, String equipe) async {
    _setLoading(true);
    try {
      final res = await ApiService.put('/coach/me', {
        'email' : email,
        'nom': nom,
        'telephone': tel,
        'nom_equipe': equipe,
      });
      coach = Coach.fromJson(res);
      AnalyticsService.trackEvent('profile_updated', token: _token);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
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
    AnalyticsService.trackEvent('player_added',
        data: {'poste': poste}, token: _token);
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
    AnalyticsService.trackEvent('player_removed',
        data: {'player_id': id}, token: _token);
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
    AnalyticsService.trackEvent('planning_created',
        data: {
          'mode': p.mode,
          'nb_seances': p.nbSeances,
          'titre': p.titre,
        },
        token: _token);
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
    AnalyticsService.trackEvent('planning_updated',
        data: {'planning_id': id}, token: _token);
    notifyListeners();
    return p;
  }

  Future<void> deletePlanning(int id) async {
    await PlanningService.deletePlanning(id);
    AnalyticsService.trackEvent('planning_deleted',
        data: {'planning_id': id}, token: _token);
    plannings.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ── Collaboration ──────────────────────────────────────────────
  Future<void> inviteCollaborator(int planningId, String email) async {
    _setLoading(true);
    try {
      await InvitationService.sendInvitation(planningId, email);
      AnalyticsService.trackEvent('invitation_sent',
          data: {'planning_id': planningId}, token: _token);
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
      AnalyticsService.trackEvent('invitation_accepted', token: _token);
      if (isLoggedIn) await loadPlannings();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Feedbacks ───────────────────────────────────────────────────
  Future<void> sendFeedback(String commentaire) async {
    _setLoading(true);
    try {
      await FeedbackService.sendFeedback(commentaire);
      AnalyticsService.trackEvent('feedback_sent', token: _token);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Admin ──────────────────────────────────────────────────────
  Future<void> loadAdminData() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        ApiService.get('/admin/stats/summary'),
        ApiService.get('/admin/coaches'),
        ApiService.get('/admin/feedbacks'),
      ]);
      adminSummary = results[0];
      adminCoaches = results[1]['data'] ?? [];
      adminFeedbacks = results[2]['data'] ?? [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchAdminCoaches(String query) async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/admin/coaches?q=$query');
      adminCoaches = res['data'] ?? [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchAdminFeedbacks(String query) async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/admin/feedbacks?q=$query');
      adminFeedbacks = res['data'] ?? [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateFeedbackStatus(int id, String status) async {
    try {
      await ApiService.put('/admin/feedbacks/$id', {'status': status});
      await loadAdminData(); // Rafraîchir tout
    } catch (_) {}
  }

  Future<void> deleteFeedback(int id) async {
    try {
      await ApiService.delete('/admin/feedbacks/$id');
      adminFeedbacks.removeWhere((f) => f['id'] == id);
      notifyListeners();
    } catch (_) {}
  }
}

//-----------------------------------
