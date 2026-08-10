import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../utils/constants.dart';
import '../widgets/vp_button.dart';
import '../widgets/planning_detail_dialog.dart';
import '../widgets/ai_generator_dialog.dart';
//import '../screen/planning/planning_form_screen.dart';
import '../models/planning.dart';
import '../models/coach.dart';
//import '../models/notification.dart';
//import 'dart:convert';
//import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;

    // Si on vient de rafraîchir la page, on attend que tryAutoLogin ait fini de tout charger
    if (!state.isInitialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.red)));
    }

    final isWide = MediaQuery.of(context).size.width > 800;
    final isAdmin = state.coach?.role == 'admin';

    final pages = [
      _DashboardTab(onSeeAll: () => setState(() => _navIndex = 1)),
      _PlanningsTab(),
      _JoueursTab(),
      _GlobalBilanTab(),
      _ProfileTab(),
      if (isAdmin) _AdminTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar (desktop)
              if (isWide)
                _Sidebar(
                    selected: _navIndex,
                    onSelect: (i) => setState(() => _navIndex = i),
                    coach: state.coach),

              // Main content
              Expanded(child: pages[_navIndex]),
            ],
          ),
          // Feedback Button (Transparent & Persistent)
          Positioned(
            bottom: 15,
            left: isWide
                ? 235
                : 15, // Ajusté pour ne pas chevaucher la sidebar ou le bord
            child: const _FeedbackButton(),
          ),
        ],
      ),
      // Bottom nav (mobile)
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
              selectedItemColor: AppColors.red,
              unselectedItemColor: AppColors.gray,
              items: [
                BottomNavigationBarItem(
                    icon: const Icon(Icons.home_rounded),
                    label: l10n.homeLabel),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: l10n.navPlannings),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.people_rounded),
                    label: l10n.navPlayers),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.analytics_rounded),
                    label: l10n.navBilan),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.person_rounded),
                    label: l10n.navProfile),
                if (isAdmin)
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.admin_panel_settings_rounded),
                      label: l10n.navAdmin),
              ],
            ),
    );
  }
}

//on rend la barre lateral responsive

// ── Sidebar desktop ───────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;
  final Coach? coach;

  const _Sidebar({required this.selected, required this.onSelect, this.coach});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (Icons.home_rounded, l10n.homeLabel),
      (Icons.calendar_month_rounded, l10n.navPlannings),
      (Icons.people_rounded, l10n.navPlayers),
      (Icons.analytics_rounded, l10n.navBilan),
      (Icons.person_rounded, l10n.navProfile),
      if (coach?.role == 'admin')
        (Icons.admin_panel_settings_rounded, l10n.navAdmin),
    ];

    return Container(
      width: 220,
      color: AppColors.charcoal,
      // Le CustomScrollView remplace la Column pour rendre le tout scrollable si l'écran est trop petit
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.red, AppColors.yellow]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child: Text('🏐', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VolleyPlan',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        Text('COACH EDITION',
                            style: TextStyle(
                                color: AppColors.yellow,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 32),

                // Nav items
                ...items.asMap().entries.map((e) {
                  final idx = e.key;
                  final (icon, label) = e.value;
                  final isSelected = selected == idx;
                  return InkWell(
                    onTap: () => onSelect(idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.red.withOpacity(0.15)
                            : Colors.transparent,
                        border: Border(
                            left: BorderSide(
                                color: isSelected
                                    ? AppColors.red
                                    : Colors.transparent,
                                width: 3)),
                      ),
                      child: Row(children: [
                        Icon(icon,
                            color:
                                isSelected ? AppColors.yellow : AppColors.gray,
                            size: 20),
                        const SizedBox(width: 12),
                        Text(label,
                            style: TextStyle(
                                color: isSelected
                                    ? AppColors.yellow
                                    : AppColors.gray,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Ce widget pousse le footer vers le bas, mais s'adapte s'il n'y a plus de place verticale
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: coach != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(coach!.nom,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          Text(coach!.nomEquipe,
                              style: const TextStyle(
                                  color: AppColors.gray, fontSize: 11)),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () {
                              context.read<AppState>().logout();
                              context.go('/login');
                            },
                            icon: const Icon(Icons.logout,
                                size: 14, color: AppColors.gray),
                            label: Text(l10n.logoutLabel,
                                style: const TextStyle(
                                    color: AppColors.gray, fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Admin Tab ─────────────────────────────────────────────────────--------------------
class _AdminTab extends StatefulWidget {
  @override
  State<_AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<_AdminTab> {
  final _coachSearchCtrl = TextEditingController();
  final _feedbackSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadAdminData();
    });
  }

  @override
  void dispose() {
    _coachSearchCtrl.dispose();
    _feedbackSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading && state.adminSummary == null)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.red));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: const Text('Administration',
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: AppColors.charcoal)),
          bottom: const TabBar(
            labelColor: AppColors.red,
            unselectedLabelColor: AppColors.gray,
            indicatorColor: AppColors.red,
            tabs: [
              Tab(text: 'Stats'),
              Tab(text: 'Coachs'),
              Tab(text: 'Feedbacks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStatsView(state),
            _buildCoachesView(state),
            _buildFeedbacksView(state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsView(AppState state) {
    final kpis = state.adminSummary?['kpis'];
    final byMode = (state.adminSummary?['plannings_by_mode'] as Map<String, dynamic>?) ?? {};

    if (kpis == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.red));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Revenu — carte hero ──────────────────────────────────
          _adminRevenueHero(kpis),
          const SizedBox(height: 24),

          // ── Forfaits actifs ──────────────────────────────────────
          _adminSection(
            title: '🏆 Forfaits actifs',
            color: const Color(0xFFFFB703),
            children: [
              _adminKpi('Free', '${(kpis['total_coaches'] ?? 0) - (kpis['coaches_basic'] ?? 0) - (kpis['coaches_premium'] ?? 0) - (kpis['coaches_premium_plus'] ?? 0)}', AppColors.gray),
              _adminKpi('Basic', '${kpis['coaches_basic'] ?? 0}', const Color(0xFF3A86FF)),
              _adminKpi('Premium', '${kpis['coaches_premium'] ?? 0}', const Color(0xFF8338EC)),
              _adminKpi('Premium+', '${kpis['coaches_premium_plus'] ?? 0}', AppColors.red),
            ],
          ),
          const SizedBox(height: 20),

          // ── Activité & Utilisateurs ──────────────────────────────
          _adminSection(
            title: '👥 Activité & Utilisateurs',
            color: const Color(0xFF3A86FF),
            children: [
              _adminKpi('Coachs inscrits', '${kpis['total_coaches'] ?? 0}', const Color(0xFF3A86FF)),
              _adminKpi('Utilisateurs actifs quotidien', '${kpis['dau'] ?? 0}', const Color(0xFF3A86FF)),
              _adminKpi('Utilisateurs actifs mensuel', '${kpis['mau'] ?? 0}', const Color(0xFF3A86FF)),
              _adminKpi('Feedbacks', '${kpis['total_feedbacks'] ?? 0}', const Color(0xFFFFB703)),
              _adminKpi('Réinitialisations MDP', '${kpis['password_resets'] ?? 0}', Colors.orange),
            ],
          ),
          const SizedBox(height: 20),

          // ── Contenu ──────────────────────────────────────────────
          _adminSection(
            title: '📋 Contenu',
            color: AppColors.red,
            children: [
              _adminKpi('Plannings', '${kpis['total_plannings'] ?? 0}', AppColors.red),
              _adminKpi('Joueurs', '${kpis['total_joueurs'] ?? 0}', const Color(0xFF06D6A0)),
              _adminKpi('Séances moy./planning', '${kpis['avg_seances'] ?? 0}', AppColors.red),
              _adminKpi('Exercices moy./planning', '${kpis['avg_exercises'] ?? 0}', AppColors.red),
              _adminKpi('Joueurs moy./coach', '${kpis['avg_players_per_coach'] ?? 0}', const Color(0xFF06D6A0)),
              _adminKpi('Actions joueurs', '${kpis['player_activity'] ?? 0}', const Color(0xFF06D6A0)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Exports & Partage ────────────────────────────────────
          _adminSection(
            title: '📤 Exports & Partage',
            color: const Color(0xFF06D6A0),
            children: [
              _adminKpi('Exports PDF', '${kpis['pdf_exports'] ?? 0}', Colors.red.shade700),
              _adminKpi('Exports Excel', '${kpis['excel_exports'] ?? 0}', const Color(0xFF1D6F42)),
              _adminKpi('Liens partagés', '${kpis['share_links_generated'] ?? 0}', const Color(0xFF06D6A0)),
              _adminKpi('Vues publiques', '${kpis['public_views'] ?? 0}', const Color(0xFF06D6A0)),
            ],
          ),
          const SizedBox(height: 20),

          // ── IA ───────────────────────────────────────────────────
          _adminSection(
            title: '✨ Intelligence Artificielle',
            color: const Color(0xFF6C47FF),
            children: [
              _adminKpi('Plannings IA générés', '${kpis['ai_plannings_generated'] ?? 0}', const Color(0xFF6C47FF)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Invitations & Collaboration ──────────────────────────
          _adminSection(
            title: '🤝 Collaboration',
            color: const Color(0xFF8338EC),
            children: [
              _adminKpi('Invitations envoyées', '${kpis['invites_sent'] ?? 0}', const Color(0xFF8338EC)),
              _adminKpi('Taux acceptation', '${kpis['acceptance_rate'] ?? 0}%', const Color(0xFF8338EC)),
              _adminKpi('Collabs moy./planning', '${kpis['avg_collaborators'] ?? 0}', const Color(0xFF8338EC)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Paiements ────────────────────────────────────────────
          _adminSection(
            title: '💳 Paiements',
            color: const Color(0xFFFFB703),
            children: [
              _adminKpi('Initiés', '${kpis['payment_initiated_count'] ?? 0}', Colors.orange),
              _adminKpi('Complétés', '${kpis['payment_completed_count'] ?? 0}', Colors.green),
              _adminKpi(
                'Taux conversion',
                () {
                  final initiated = (kpis['payment_initiated_count'] ?? 0) as int;
                  final completed = (kpis['payment_completed_count'] ?? 0) as int;
                  if (initiated == 0) return '—';
                  return '${(completed / initiated * 100).toStringAsFixed(0)}%';
                }(),
                const Color(0xFFFFB703),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Répartition par mode ──────────────────────────────────
          const Text('Répartition par mode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.charcoal)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: byMode.entries.map((e) {
                return ListTile(
                  title: Text(e.key == 'groupe' ? '👥 Groupe' : '🎯 Spécifique'),
                  trailing: Text('${e.value}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Carte hero pour le revenu total — plus grande et plus visible
  Widget _adminRevenueHero(Map<String, dynamic> kpis) {
    final revenue = kpis['revenue_total_xaf'] ?? 0;
    final initiated = kpis['payment_initiated_count'] ?? 0;
    final completed = kpis['payment_completed_count'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D6F42), Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D6F42).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text('Revenu total', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(
            '${_formatRevenue(revenue)} XAF',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _revenuePill('💰 $initiated initiés', Colors.white.withOpacity(0.2)),
            const SizedBox(width: 8),
            _revenuePill('✅ $completed complétés', Colors.white.withOpacity(0.2)),
          ]),
        ],
      ),
    );
  }

  Widget _revenuePill(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _formatRevenue(dynamic value) {
    final n = (value is int) ? value : int.tryParse(value.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }

  /// Groupe de KPIs avec titre de section
  Widget _adminSection({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.charcoal)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: children),
      ],
    );
  }

  Widget _adminKpi(String label, String value, Color color) {
    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.gray, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildCoachesView(AppState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _coachSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher un coach...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _coachSearchCtrl.clear();
                    state.loadAdminData();
                  }),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (val) => state.searchAdminCoaches(val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.adminCoaches.length,
            itemBuilder: (context, index) {
              final coach = state.adminCoaches[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: AppColors.grayLight,
                      child: Icon(Icons.person, color: AppColors.gray)),
                  title: Text(coach['nom'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${coach['email']}\n${coach['nom_equipe']}"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${coach['plannings_count']} plannings",
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      if (coach['last_activity'] != null)
                        Text("Actif: ${_formatDate(coach['last_activity'])}",
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.gray)),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbacksView(AppState state) {
    if (state.adminFeedbacks.isEmpty)
      return const Center(child: Text('Aucun feedback pour le moment.'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _feedbackSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher un feedback...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _feedbackSearchCtrl.clear();
                    state.loadAdminData();
                  }),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (val) => state.searchAdminFeedbacks(val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.adminFeedbacks.length,
            itemBuilder: (context, index) {
              final f = state.adminFeedbacks[index];
              final isProcessed = f['status'] == 'processed';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grayLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f['coach_name'] ?? 'Inconnu',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.red)),
                        Text(_formatDate(f['created_at']),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.gray)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(f['content'] ?? "N/A",
                        style: const TextStyle(fontSize: 14, height: 1.4)),
                    const SizedBox(height: 8),
                    Text(f['coach_email'] ?? "N/A",
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gray,
                            fontStyle: FontStyle.italic)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isProcessed)
                          TextButton.icon(
                            onPressed: () => state.updateFeedbackStatus(
                                f['id'], 'processed'),
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: const Text('Marquer comme traité',
                                style: TextStyle(fontSize: 12)),
                          )
                        else
                          const Row(children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                            SizedBox(width: 4),
                            Text('Traité',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ]),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.red, size: 20),
                          onPressed: () => state.deleteFeedback(f['id']),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic iso) {
    if (iso == null) return "--/--/----";
    try {
      final date = DateTime.parse(iso.toString());
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return iso.toString();
    }
  }
}

//-----------------PROFIL---------------------
class _ProfileTab extends StatefulWidget {
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _emailCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _equipeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final coach = context.read<AppState>().coach;
    if (coach != null) {
      _emailCtrl.text = coach.email;
      _nomCtrl.text = coach.nom;
      _telCtrl.text = coach.telephone;
      _equipeCtrl.text = coach.nomEquipe;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _equipeCtrl.dispose();
    super.dispose();
  }

  String _formatForfait(String? forfait, AppLocalizations l10n) {
    final normalized = (forfait ?? 'FREE').toUpperCase();
    switch (normalized) {
      case 'FREE':
      case 'DECOUVERTE':
        return l10n.profileSubscriptionFree;
      case 'BASIC':
        return 'Basic';
      case 'PREMIUM':
        return 'Premium';
      case 'PREMIUM_PLUS':
        return 'Premium+';
      default:
        return forfait ?? l10n.profileSubscriptionFree;
    }
  }

  String _formatExpiry(DateTime? expiry, AppLocalizations l10n) {
    if (expiry == null) return l10n.profileSubscriptionNoExpiry;
    return DateFormat('dd/MM/yyyy').format(expiry);
  }

  Widget _buildSubscriptionTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isCompact,
  }) {
    return Container(
      width: isCompact ? double.infinity : 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grayXLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayLight.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;
    final coach = state.coach;
    final isCompact = MediaQuery.of(context).size.width < 650;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.profileTitle,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ]),
            child: Column(
              children: [
                TextField(
                  controller: _emailCtrl,
                  //readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n.profileEmailReadonly,
                    prefixIcon: const Icon(Icons.email_outlined),
                    //filled: true,
                    //fillColor: AppColors.grayXLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      //borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nomCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.fullNameField,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _telCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.phoneField,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _equipeCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.teamNameField,
                    prefixIcon: const Icon(Icons.group_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.grayLight.withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileSubscriptionSectionTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildSubscriptionTile(
                            icon: Icons.workspace_premium_rounded,
                            title: l10n.profileSubscriptionPlanLabel,
                            value: _formatForfait(coach?.forfait, l10n),
                            isCompact: isCompact,
                          ),
                          _buildSubscriptionTile(
                            icon: Icons.event_available_rounded,
                            title: l10n.profileSubscriptionExpiryLabel,
                            value: _formatExpiry(coach?.expireForfait, l10n),
                            isCompact: isCompact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                VpButton(
                  label: l10n.profileSaveAction,
                  loading: state.loading,
                  onPressed: () async {
                    try {
                      await state.updateProfile(
                          _emailCtrl.text,_nomCtrl.text, _telCtrl.text, _equipeCtrl.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.profileUpdateSuccess)));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(l10n.errorPrefix(e.toString())),
                            backgroundColor: AppColors.red));
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                VpButton(
                  label: l10n.profileManageSubscription,
                  variant: VpButtonVariant.secondary,
                  icon: Icons.card_membership,
                  onPressed: () {
                    context.push('/tarifs');
                  },
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.grayLight),
                const SizedBox(height: 24),
                VpButton(
                  label: l10n.logoutLabel,
                  variant: VpButtonVariant.danger,
                  icon: Icons.logout,
                  onPressed: () {
                    context.read<AppState>().logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _DashboardTab({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;

    // On ne calcule les stats que sur nos propres plannings
    final myPlannings =
        state.plannings.where((p) => p.isOwner(state.coach?.id)).toList();

    final totalVol = myPlannings.fold(0, (s, p) => s + p.volumeTotal);
    final totalSeances = myPlannings.fold(0, (s, p) => s + p.seances.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.welcomeCoach(state.coach?.nom ?? "Coach"),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal)),
          Text(state.coach?.nomEquipe ?? '',
              style: const TextStyle(color: AppColors.gray, fontSize: 14)),
          const SizedBox(height: 28),

          // Notifications Feed
          if (state.notifications.isNotEmpty) ...[
            ...state.notifications.map((n) {
              // Détermine si c'est une notif de présence cliquable
              final isPresence = n.isPresenceRappel && n.seanceId != null;

              return GestureDetector(
                onTap: isPresence
                    ? () {
                        state.dismissNotification(n.id);
                        context.push('/presence/${n.seanceId}');
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isPresence
                        ? AppColors.red.withOpacity(0.08)
                        : AppColors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPresence
                          ? AppColors.red.withOpacity(0.3)
                          : AppColors.yellow.withOpacity(0.3),
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      isPresence
                          ? Icons.how_to_reg_rounded
                          : Icons.info_outline,
                      color: isPresence ? AppColors.red : AppColors.yellowDark,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.message,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if (isPresence) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.tapToMarkAttendance,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.red.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isPresence)
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.red),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.gray),
                      onPressed: () => state.dismissNotification(n.id),
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // KPIs
          Wrap(spacing: 16, runSpacing: 16, children: [
            _kpi(l10n.navPlannings, '${myPlannings.length}', AppColors.red,
                Icons.calendar_month_rounded),
            _kpi(l10n.dashboardKpiSessions, '$totalSeances',
                const Color(0xFF3A86FF), Icons.event_note_rounded),
            _kpi(l10n.dashboardKpiVolume, AppConstants.fmtMinutes(totalVol),
                AppColors.yellow, Icons.timer_rounded),
            _kpi(l10n.navPlayers, '${state.joueurs.length}',
                const Color(0xFF06D6A0), Icons.people_rounded),
          ]),
          const SizedBox(height: 32),

          // Plannings récents
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.dashboardRecentPlannings,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal)),
              TextButton(
                  onPressed: onSeeAll,
                  child: Text(l10n.dashboardSeeAll,
                      style: const TextStyle(color: AppColors.red))),
            ],
          ),
          const SizedBox(height: 12),
          ...myPlannings.take(3).map((p) => _PlanningCard(planning: p)),

          const SizedBox(height: 24),
          // CTA
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.charcoal, Color(0xFF2d2d4e)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(l10n.dashboardCreatePlanningTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Text(l10n.dashboardCreatePlanningSubtitle,
                          style: const TextStyle(
                              color: AppColors.gray, fontSize: 13)),
                    ])),
                VpButton(
                    label: l10n.dashboardStartAction,
                    onPressed: () => context.push('/planning/create'),
                    icon: Icons.add),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, Color color, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.gray,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Plannings Tab ─────────────────────────────────────────────────
class _PlanningsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton IA ✨
          FloatingActionButton.extended(
            heroTag: 'fab_ai',
            onPressed: () async {
              final result = await showAiGeneratorDialog(context);
              if (result != null && context.mounted) {
                await context.push('/planning/create', extra: result);
                // Rafraîchir la liste des plannings après retour
                if (context.mounted) {
                  context.read<AppState>().loadPlannings();
                }
              }
            },
            backgroundColor: const Color(0xFF6C47FF),
            foregroundColor: Colors.white,
            icon: const Text('✨', style: TextStyle(fontSize: 18)),
            label: Text(l10n.homeFabAiLabel,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          // Bouton classique
          FloatingActionButton.extended(
            heroTag: 'fab_new',
            onPressed: () => context.push('/planning/create'),
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(l10n.btnNew,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : state.plannings.isEmpty
              ? _empty(context, l10n)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.plannings.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0)
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(l10n.myPlanningsTitle,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.charcoal)),
                      );
                    return _PlanningCard(planning: state.plannings[i - 1]);
                  },
                ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(l10n.noPlanningsTitle,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal)),
          const SizedBox(height: 8),
          Text(l10n.noPlanningsSubtitle,
              style: const TextStyle(color: AppColors.gray)),
          const SizedBox(height: 24),
          VpButton(
              label: l10n.btnCreatePlanning,
              onPressed: () => context.push('/planning/create'),
              icon: Icons.add),
        ],
      ));
}

void _showPlanningDetailDialog(BuildContext context, int planningId) {
  showDialog(
    context: context,
    builder: (ctx) => PlanningDetailDialog(planningId: planningId),
    barrierDismissible: true, // Permet de fermer en cliquant à l'extérieur
    useSafeArea: true, // S'assure que le dialog respecte les zones de sécurité
  );
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      // On augmente l'opacité pour qu'il soit plus visible
      opacity: 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFeedbackDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(
                12), // On augmente le padding pour agrandir le bouton
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray, width: 1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.message_outlined,
                size: 24,
                color: AppColors.gray), // On augmente la taille de l'icône
          ),
        ),
      ),
    );
  }
}

void _showFeedbackDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final ctrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.feedbackTitle,
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.charcoal)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.feedbackSubtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.feedbackHint,
              filled: true,
              fillColor: AppColors.grayXLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.feedbackLater)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            if (ctrl.text.trim().isEmpty) return;
            await context.read<AppState>().sendFeedback(ctrl.text.trim());
            if (context.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.feedbackSuccess)),
              );
            }
          },
          child: Text(l10n.feedbackSend),
        ),
      ],
    ),
  );
}

// ── Joueurs Tab ───────────────────────────────────────────────────
class _JoueursTab extends StatefulWidget {
  @override
  State<_JoueursTab> createState() => _JoueursTabState();
}

class _JoueursTabState extends State<_JoueursTab> {
  final _nomCtrl = TextEditingController();
  String? _posteSelected;
//on rend l'ajoute de joueur responsive

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    // Détection de la largeur de la fenêtre pour éviter l'overflow horizontal sur mobile
    final isNarrow = MediaQuery.of(context).size.width < 650;

    String getPosteLabel(String p) {
      switch (p) {
        case 'Passeur':
          return l10n.postePasseur;
        case 'Libéro':
          return l10n.posteLibero;
        case 'Central':
          return l10n.posteCentral;
        case 'Pointu':
          return l10n.postePointu;
        case 'Réceptionneur-Attaquant':
          return l10n.posteReceptionneurAttaquant;
        case 'Universal':
          return l10n.posteUniversal;
        default:
          return p;
      }
    }

    final isPremiumCoach = state.coach?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.myPlayersTitle,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal)),
            const SizedBox(height: 20),
            if (!isPremiumCoach)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.yellowLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: AppColors.yellowDark, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.passerAuPremium,
                        style: const TextStyle(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w600,
                            height: 1.4),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/tarifs'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.red,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: Text(l10n.voirTarifs), //'Voir tarifs'),
                    ),
                  ],
                ),
              ),

            // Ajout joueur
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.addPlayerTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal)),
                  const SizedBox(height: 12),

                  // SI L'ÉCRAN EST ÉTROIT : On empile les champs verticalement (Column)
                  if (isNarrow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nomCtrl,
                          decoration: InputDecoration(
                            // Removed const
                            hintText: l10n.playerNameHint,
                            filled: true,
                            fillColor: AppColors.grayXLight,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _posteSelected,
                          hint: Text(l10n.positionHint), // Removed const
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.grayXLight,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          items: AppConstants.postes
                              .map((p) => DropdownMenuItem(
                                  value: p, // Removed const
                                  child: Text(getPosteLabel(p),
                                      style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) => setState(() => _posteSelected = v),
                        ),
                        const SizedBox(height: 16),
                        VpButton(
                            label: l10n.addPlayerButton,
                            onPressed: () async {
                              if (_nomCtrl.text.isEmpty) return;
                              await state.addJoueur(_nomCtrl.text.trim(),
                                  poste: _posteSelected);
                              _nomCtrl.clear();
                              setState(() => _posteSelected = null);
                            }),
                      ],
                    )
                  // SI L'ÉCRAN EST RESTE LARGE : On garde la disposition en ligne (Row)
                  else
                    Row(children: [
                      Expanded(
                          child: TextField(
                        controller: _nomCtrl, // Removed const
                        decoration: InputDecoration(
                          // Removed const
                          hintText: l10n.playerNameHint,
                          filled: true,
                          fillColor: AppColors.grayXLight,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      )),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _posteSelected, // Removed const
                        hint: Text(l10n.positionHint), // Removed const
                        items: AppConstants.postes
                            .map((p) => DropdownMenuItem(
                                value: p, // Removed const
                                child: Text(getPosteLabel(p),
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _posteSelected = v),
                      ),
                      const SizedBox(width: 10),
                      VpButton(
                          label: l10n.addPlayerShortButton,
                          small: true,
                          onPressed: () async {
                            if (_nomCtrl.text.isEmpty) return;
                            await state.addJoueur(_nomCtrl.text.trim(),
                                poste: _posteSelected);
                            _nomCtrl.clear();
                            setState(() => _posteSelected = null);
                          }),
                    ]),
                ],
              ),
            ),
            if (state.joueurs.isEmpty)
              Center(
                  child: Text(l10n.noPlayersMessage,
                      style: const TextStyle(
                          color: AppColors.gray, fontStyle: FontStyle.italic))),
            const SizedBox(height: 20),

            // Liste joueurs
            ...state.joueurs.map((j) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.redLight,
                      child: Text(j.nom[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w800)),
                    ),
                    title: Text(j.nom,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: j.poste != null
                        ? Text(getPosteLabel(j.poste!),
                            style: const TextStyle(
                                color: AppColors.gray, fontSize: 12))
                        : null,
                    trailing: const Icon(Icons.more_vert,
                        color: AppColors.gray, size: 20),
                    onTap: () => _showPlayerOptions(context, j),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showPlayerOptions(BuildContext context, j) {
    final l10n = AppLocalizations.of(context)!;
    final isPremiumCoach = context.read<AppState>().coach?.isPremium ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  j.nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.charcoal),
                ),
              ),
              const Divider(height: 1, color: AppColors.grayLight),
              ListTile(
                leading: const Icon(Icons.person_pin_outlined,
                    color: AppColors.red, size: 24),
                title: Row(
                  children: [
                    Text(l10n.playerProfile,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal)),
                    if (!isPremiumCoach) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text('PREMIUM',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: !isPremiumCoach
                    ? Text(
                        l10n.accerderProfil,
                        //'Passez au forfait Premium pour accéder au profil',
                        style: TextStyle(color: AppColors.gray, fontSize: 12),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isPremiumCoach) {
                    context.push('/tarifs');
                  } else {
                    context.push('/joueur/${j.id}');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: AppColors.charcoal, size: 24),
                title: Text(l10n.editPlayerTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(context, j);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.red, size: 24),
                title: Text(l10n.deletePlayerTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, j.id, j.nom, l10n);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, joueur) {
    final ctrl = TextEditingController(text: joueur.nom);
    String? poste = joueur.poste;
    final l10n = AppLocalizations.of(context)!;
    String getPosteLabel(String p) {
      switch (p) {
        case 'Passeur':
          return l10n.postePasseur;
        case 'Libéro':
          return l10n.posteLibero;
        case 'Central':
          return l10n.posteCentral;
        case 'Pointu':
          return l10n.postePointu;
        case 'Réceptionneur-Attaquant':
          return l10n.posteReceptionneurAttaquant;
        case 'Universal':
          return l10n.posteUniversal;
        default:
          return p;
      }
    }

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(l10n.editPlayerTitle),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: ctrl,
                    decoration: InputDecoration(labelText: l10n.nameLabel)),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: poste,
                  isExpanded: true,
                  hint: Text(l10n.positionHint),
                  items: AppConstants.postes
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(getPosteLabel(p))))
                      .toList(),
                  onChanged: (v) {
                    poste = v;
                    (ctx as Element).markNeedsBuild();
                  },
                ),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx), // Removed const
                    child: Text(l10n.cancelButton)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    await context.read<AppState>().updateJoueur(
                        joueur.id, {'nom': ctrl.text, 'poste': poste});
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: Text(l10n.saveButton),
                ),
              ],
            ));
  }

  void _confirmDelete(
      BuildContext context, int id, String nom, AppLocalizations l10n) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(l10n.deletePlayerTitle),
              content: Text(l10n.deletePlayerConfirmation(nom)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx), // Removed const
                    child: Text(l10n.cancelButton)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    await context.read<AppState>().removeJoueur(id);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: Text(l10n.deleteButton),
                ),
              ],
            ));
  }
}

// ── Planning Card ─────────────────────────────────────────────────
class _PlanningCard extends StatelessWidget {
  final Planning planning;
  const _PlanningCard({required this.planning});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String getDomaineLabel(String id) {
      switch (id.toLowerCase()) {
        case 'service':
          return l10n.domaineService;
        case 'reception':
          return l10n.domaineReception;
        case 'passe':
          return l10n.domainePasse;
        case 'attaque':
          return l10n.domaineAttaque;
        case 'block':
          return l10n.domaineBlock;
        case 'defense':
          return l10n.domaineDefense;
        case 'physique':
          return l10n.domainePhysique;
        case 'general':
          return l10n.domaineGeneral;
        default:
          return id;
      }
    }

    final domaines =
        planning.seances.expand((s) => s.domaines).toSet().toList();

    return GestureDetector(
      onTap: () => _showPlanningDetailDialog(context, planning.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
              left: BorderSide(
                  color: planning.mode == 'groupe'
                      ? AppColors.red
                      : AppColors.yellow,
                  width: 4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: planning.mode == 'groupe'
                        ? AppColors.redLight
                        : AppColors.yellowLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    planning.mode == 'groupe'
                        ? '👥 ${l10n.modeGroup}'
                        : '🎯 ${planning.poste ?? l10n.modeIndividual}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: planning.mode == 'groupe'
                            ? AppColors.red
                            : AppColors.yellowDark),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.gray),
              ],
            ),
            const SizedBox(height: 10),
            Text(planning.titre,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.charcoal)),
            const SizedBox(height: 10),
            Row(children: [
              _stat('${planning.seances.length}', l10n.labelSessionsSmall,
                  AppColors.red),
              const SizedBox(width: 20),
              _stat(AppConstants.fmtMinutes(planning.volumeTotal),
                  l10n.labelVolumeSmall, AppColors.charcoal),
              const SizedBox(width: 20),
              _stat('${planning.joueurs.length}', l10n.labelPlayersSmall,
                  AppColors.charcoal),
            ]),
            if (domaines.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                  spacing: 5,
                  children: domaines
                      .take(4)
                      .map((d) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.domaineColor(d)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                '${AppConstants.domaineIcon(d)} ${getDomaineLabel(d)}',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppConstants.domaineColor(d),
                                    fontWeight: FontWeight.w700)),
                          ))
                      .toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Row(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.gray)),
        ],
      );
}

// ── Bilan Global Tab ──────────────────────────────────────────────
class _GlobalBilanTab extends StatefulWidget {
  @override
  State<_GlobalBilanTab> createState() => _GlobalBilanTabState();
}

class _GlobalBilanTabState extends State<_GlobalBilanTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadGlobalBilan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bilan = state.globalBilan;
    final l10n = AppLocalizations.of(context)!;

    String getDomaineLabel(String id) {
      switch (id.toLowerCase()) {
        case 'service':
          return l10n.domaineService;
        case 'reception':
          return l10n.domaineReception;
        case 'passe':
          return l10n.domainePasse;
        case 'attaque':
          return l10n.domaineAttaque;
        case 'block':
          return l10n.domaineBlock;
        case 'defense':
          return l10n.domaineDefense;
        case 'physique':
          return l10n.domainePhysique;
        case 'general':
          return l10n.domaineGeneral;
        default:
          return id;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.globalBilanTitle,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal)),
            const SizedBox(height: 8),
            Text(l10n.globalBilanSubtitle,
                style: const TextStyle(color: AppColors.gray, fontSize: 14)),
            const SizedBox(height: 32),
            if (state.loading && bilan == null)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.red))
            else if (bilan == null)
              Center(child: Text(l10n.noDataAvailable))
            else ...[
              // KPIs Globaux
              Wrap(spacing: 16, runSpacing: 16, children: [
                _statCard(l10n.kpiTotalPlannings, '${bilan['nb_plannings']}',
                    Icons.collections_bookmark_rounded),
                _statCard(l10n.kpiTotalSessions, '${bilan['nb_seances']}',
                    Icons.event_available_rounded),
                _statCard(
                    l10n.kpiTotalVolume,
                    AppConstants.fmtMinutes(bilan['total_minutes']),
                    Icons.timer_rounded),
                _statCard(
                    l10n.kpiAvgPerSession,
                    AppConstants.fmtMinutes(bilan['avg_seance_minutes']),
                    Icons.av_timer_rounded),
              ]),
              const SizedBox(height: 40),

              // Répartition
              Text(l10n.globalDistributionTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: (bilan['domain_stats'] as List).map((d) {
                    if (d['minutes'] == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(getDomaineLabel(d['id']),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  '${d['pct']}% (${AppConstants.fmtMinutes(d['minutes'])})',
                                  style: const TextStyle(
                                      color: AppColors.gray, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: d['pct'] / 100,
                            backgroundColor: AppColors.grayXLight,
                            color: AppConstants.domaineColor(d['id']),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Recommandations
              Text(l10n.analysisAndAdviceTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...(bilan['recommandations'] as List).map((rec) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.red.withOpacity(0.1)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.insights_rounded,
                          color: AppColors.red, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                          child:
                              Text(rec, style: const TextStyle(fontSize: 13))),
                    ]),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.red, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.gray)),
      ]),
    );
  }
}
