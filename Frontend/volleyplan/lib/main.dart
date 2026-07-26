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
import 'package:flutter_localizations/flutter_localizations.dart'; // Import pour les délégateurs standards
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import généré
import 'package:seo_renderer/seo_renderer.dart'; // Import pour le SEO

import 'screen/private_screen.dart'; // Importe ta page de confidentialité
import 'screen/terms_screen.dart'; // Importe ta page de conditions
import 'screen/blog_screen.dart';
import 'screen/blog_detail_screen.dart';
import 'screen/joueur_detail_screen.dart';
import 'screen/presence_screen.dart';
import 'screen/tarif_screen.dart';
import 'screen/planning/public_planning_screen.dart';
//import 'screen/executer_seance_screen.dart';

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

class VolleyPlanApp extends StatefulWidget {
  const VolleyPlanApp({super.key});

  @override
  State<VolleyPlanApp> createState() => _VolleyPlanAppState();
}

class _VolleyPlanAppState extends State<VolleyPlanApp> {
  late final GoRouter _routerConfig;

  @override
  void initState() {
    super.initState();
    // On initialise le router une seule fois lors de la création de l'app.
    // Il continuera d'écouter les changements (comme le login/logout) via refreshListenable.
    final appState = Provider.of<AppState>(context, listen: false);
    _routerConfig = _createRouter(appState);
  }

  @override
  Widget build(BuildContext context) {
    // On watch AppState ici uniquement pour la locale (changement de langue)
    final appState = context.watch<AppState>();

    // On enveloppe l'application avec RobotDetector pour activer le SEO
    return RobotDetector(
      child: MaterialApp.router(
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
        // --- Configuration de la localisation ---
        localizationsDelegates: const [
          AppLocalizations.delegate, // Délégataire généré par l'outil
          GlobalMaterialLocalizations
              .delegate, // Localisation des widgets Material Design
          GlobalWidgetsLocalizations
              .delegate, // Localisation des widgets standards
          GlobalCupertinoLocalizations
              .delegate, // Localisation des widgets iOS-style
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: appState.currentLocale, // Utilise la locale de AppState
        // --- Fin de la configuration de la localisation ---
        routerConfig: _routerConfig,
      ),
    );
  }

  // Méthode pour configurer l'instance unique du router
  GoRouter _createRouter(AppState appState) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: appState,
      redirect: (context, state) {
        final bool loggedIn = appState.isLoggedIn;
        final bool initializing = !appState.isInitialized;
        final String loc = state.matchedLocation;
        final bool isAuthPage = loc == '/login' || loc == '/register';

        if (initializing) return null;

        if (!loggedIn &&
            !isAuthPage &&
            loc != '/' &&
            !loc.startsWith('/invite') &&
            !loc.startsWith('/collaborations') &&
            !loc.startsWith('/reset-password') &&
            !loc.startsWith('/tarifs') &&
            !loc.startsWith('/planning') &&
            !loc.startsWith('/public') &&
            loc != '/privacy' &&
            loc != '/terms' &&
            !loc.startsWith('/blog')) {
          return '/login';
        }

        // If the user just registered, let them visit the tarifs page first.
        if (appState.justRegistered) return null;

        if (loggedIn && (isAuthPage || loc == '/') && loc != '/tarifs')
          return '/home';

        return null;
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return _GlobalLanguageWrapper(child: child);
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
              path: '/blog',
              builder: (context, state) => const BlogScreen(),
            ),
            GoRoute(
              path: '/blog/:slug',
              builder: (context, state) {
                final slug = state.pathParameters['slug'] ?? '';
                return BlogDetailScreen(slug: slug);
              },
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
              path: '/tarifs',
              builder: (context, state) => const TarifScreen(),
            ),
            GoRoute(
              path: '/planning/create',
              builder: (context, state) {
                final aiData = state.extra as Map<String, dynamic>?;
                return PlanningFormScreen(aiData: aiData);
              },
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
            GoRoute(
              path: '/joueur/:id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return JoueurDetailScreen(joueurId: id);
              },
            ),
            GoRoute(
              path: '/presence/:seanceId',
              builder: (context, state) {
                final seanceId =
                    int.tryParse(state.pathParameters['seanceId'] ?? '') ?? 0;
                return PresenceScreen(seanceId: seanceId);
              },
            ),
            GoRoute(
              path: '/public/planning/:token',
              builder: (context, state) => PublicPlanningScreen(
                token: state.pathParameters['token']!,
              ),
            ),
            /*GoRoute(
              path: '/executer-seance/:seanceId',
              builder: (context, state) {
                final seanceId =
                    int.tryParse(state.pathParameters['seanceId'] ?? '') ?? 0;
                return ExecuterSeanceScreen(planningId: planningId, seanceId: seanceId);
              },
            ),*/
          ],
        ),
      ],
    );
  }
}

/// Widget qui enveloppe toute l'application avec une barre de langue "discrète"
class _GlobalLanguageWrapper extends StatefulWidget {
  final Widget child;
  const _GlobalLanguageWrapper({required this.child});

  @override
  State<_GlobalLanguageWrapper> createState() => _GlobalLanguageWrapperState();
}

class _GlobalLanguageWrapperState extends State<_GlobalLanguageWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            right: 0,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isHovered
                    ? 1.0
                    : 0.2, // Disparaît (devient translucide) si pas utilisé
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12)),
                  ),
                  child: PopupMenuButton<Locale>(
                    tooltip: 'Changer la langue',
                    icon: const Icon(Icons.language,
                        color: Colors.white, size: 18),
                    onSelected: (Locale locale) => appState.setLocale(locale),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: Locale('fr'), child: Text('🇫🇷 Français')),
                      const PopupMenuItem(
                          value: Locale('en'), child: Text('🇺🇸 English')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


//---------------------------