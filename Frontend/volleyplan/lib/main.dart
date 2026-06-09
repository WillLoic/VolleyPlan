import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screen/auth/login_screen.dart';
import 'screen/auth/register_screen.dart';
import 'screen/home_screen.dart';
import 'screen/planning/planning_form_screen.dart';
import 'screen/invitation_screen.dart';
import 'screen/collaborator_dashboard.dart';
import 'utils/constants.dart';
import 'screen/auth/reset_password_screen.dart';
import 'screen/landing_screen.dart';
import 'services/analytics_service.dart';
import 'screen/private_screen.dart'; // Importe ta page de confidentialité
import 'screen/terms_screen.dart'; // Importe ta page de conditions

void main() {
  // On s'assure que les bindings Flutter sont prêts
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  // Initialisation de la session d'analytics
  AnalyticsService.initSession();
  // On lance la tentative de reconnexion automatique en arrière-plan
  appState.tryAutoLogin();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const VolleyPlanApp(),
    ),
  );
}

class VolleyPlanApp extends StatelessWidget {
  const VolleyPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // by the _incrementCounter method above.
    return MaterialApp.router(
      title: 'VolleyPlan Coach Edition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.red,
          primary: AppColors.red,
        ),
        scaffoldBackgroundColor: AppColors.offWhite,
      ),
      routerConfig: _router(context.read<AppState>()),
    );
  }

  // On transforme le router en fonction pour qu'il puisse écouter AppState
  static GoRouter _router(AppState appState) => GoRouter(
        initialLocation: '/',
        refreshListenable:
            appState, // Le router se rafraîchit quand l'état change
        redirect: (context, state) {
          final bool loggedIn = appState.isLoggedIn;
          final bool initializing = !appState.isInitialized;

          // Liste des routes d'authentification
          final String loc = state.matchedLocation;
          final bool isAuthPage = loc == '/login' || loc == '/register';

          // Tant qu'on n'a pas fini de vérifier le token, on ne redirige pas
          if (initializing) return null;

          // Si pas connecté, on autorise la landing, les pages d'auth, d'invitation, de collaboration et de planning
          if (!loggedIn &&
              !isAuthPage &&
              loc != '/' &&
              !loc.startsWith('/invite') &&
              !loc.startsWith('/collaborations') &&
              !loc.startsWith('/reset-password') &&
              !loc.startsWith('/planning') &&
              loc != '/privacy' && // Autoriser la page de confidentialité
              loc != '/terms') // Autoriser la page des conditions d'utilisation
          {
            return '/login';
          }

          // Si connecté et sur la landing ou page d'auth -> vers home
          if (loggedIn && (isAuthPage || loc == '/')) return '/home';

          return null;
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LandingScreen(),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: '/terms',
            builder: (context, state) => const TermsScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/reset-password',
            builder: (context, state) {
              final token = state.uri.queryParameters['token'] ?? '';
              return ResetPasswordScreen(token: token);
            },
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/planning/create',
            builder: (context, state) => const PlanningFormScreen(),
          ),
          GoRoute(
            path: '/invite/:token',
            builder: (context, state) =>
                InvitationScreen(token: state.pathParameters['token'] ?? ''),
          ),
          GoRoute(
            path: '/collaborations/:token',
            builder: (context, state) =>
                CollaboratorDashboard(token: state.pathParameters['token']),
          ),
          GoRoute(
            path: '/planning/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              final token = state.uri.queryParameters['token'];
              return PlanningFormScreen(planningId: id, token: token);
            },
          ),
        ],
      );
}
