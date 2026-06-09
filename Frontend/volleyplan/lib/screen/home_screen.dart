//-----------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/constants.dart';
import '../widgets/vp_button.dart';
import '../widgets/planning_detail_dialog.dart';
import '../models/planning.dart';
import '../models/coach.dart';
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

    // Si on vient de rafraîchir la page, on attend que tryAutoLogin ait fini de tout charger
    if (!state.isInitialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.red)));
    }

    final isWide = MediaQuery.of(context).size.width > 800;
    final isAdmin = state.coach?.role == 'admin';

    final pages = [
      _DashboardTab(),
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
                const BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), label: 'Accueil'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_rounded),
                    label: 'Plannings'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.people_rounded), label: 'Joueurs'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_rounded), label: 'Bilan'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded), label: 'Profil'),
                if (isAdmin)
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.admin_panel_settings_rounded),
                      label: 'Admin'),
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
    final items = [
      (Icons.home_rounded, 'Accueil'),
      (Icons.calendar_month_rounded, 'Plannings'),
      (Icons.people_rounded, 'Joueurs'),
      (Icons.analytics_rounded, 'Bilan Global'),
      (Icons.person_rounded, 'Profil'),
      if (coach?.role == 'admin')
        (Icons.admin_panel_settings_rounded, 'Dashboard Admin'),
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
                            label: const Text('Déconnexion',
                                style: TextStyle(
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

// ── Admin Tab ─────────────────────────────────────────────────────
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _adminKpi('Coachs inscrits', '${kpis?['total_coaches']}', Colors.blue),
              _adminKpi('utilisateurs actifs quotidien/utilisateurs actifs mensuel', '${kpis?['dau']} / ${kpis?['mau']}',
                  Colors.blueAccent),
              _adminKpi(
                  'Plannings total', '${kpis?['total_plannings']}', AppColors.red),
              _adminKpi(
                  'Nombre de seance moyen par planning', '${kpis?['avg_seances']}', AppColors.red),
              _adminKpi(
                  'Nombre d\'exercice moyen par planning', '${kpis?['avg_exercises']}', AppColors.red),
              _adminKpi('nombre de PDF Exporter', '${kpis?['pdf_exports']}', Colors.green),
              _adminKpi('Nombre total de Joueurs', '${kpis?['total_joueurs']}',
                  const Color(0xFF06D6A0)),
              _adminKpi('Nombre de joueurs moyen par coach', '${kpis?['avg_players_per_coach']}',
                  const Color(0xFF06D6A0)),
              _adminKpi('Nombre de manipulation sur les joueurs', '${kpis?['player_activity']}',
                  const Color(0xFF06D6A0)),
              _adminKpi('Nombre total d\'invitations envoyes', '${kpis?['invites_sent']}',
                  const Color(0xFF8338EC)),
              _adminKpi('Pourcentage d\'invitation acceptees', '${kpis?['acceptance_rate']}%',
                  const Color(0xFF8338EC)),
              _adminKpi('Nombre de collaboration moyen par planning', '${kpis?['avg_collaborators']}',
                  const Color(0xFF8338EC)),
              _adminKpi('Nombre de requette de Mots de passe oublies', '${kpis?['password_resets']}',
                  Colors.orange),
              _adminKpi(
                  'Nombre total de Feedbacks', '${kpis?['total_feedbacks']}', AppColors.yellow),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Répartition par mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: (state.adminSummary?['plannings_by_mode']
                      as Map<String, dynamic>)
                  .entries
                  .map((e) {
                return ListTile(
                  title:
                      Text(e.key == 'groupe' ? '👥 Groupe' : '🎯 Spécifique'),
                  trailing: Text('${e.value}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminKpi(String label, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.gray)),
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mon Profil',
              style: TextStyle(
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
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Email (non modifiable)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: AppColors.grayXLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nomCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom Complet',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _telCtrl,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _equipeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'équipe',
                    prefixIcon: const Icon(Icons.group_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 32),
                VpButton(
                  label: 'Sauvegarder les modifications',
                  loading: state.loading,
                  onPressed: () async {
                    try {
                      await state.updateProfile(
                          _nomCtrl.text, _telCtrl.text, _equipeCtrl.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Profil mis à jour !')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: AppColors.red));
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.grayLight),
                const SizedBox(height: 24),
                VpButton(
                  label: 'Déconnexion',
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
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

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
          Text('Bonjour coach, ${state.coach?.nom ?? "Coach"} 👋',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal)),
          Text(state.coach?.nomEquipe ?? '',
              style: const TextStyle(color: AppColors.gray, fontSize: 14)),
          const SizedBox(height: 28),

          // Notifications Feed
          if (state.notifications.isNotEmpty) ...[
            ...state.notifications.map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.yellow.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.yellowDark, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(n.message,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600))),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.gray),
                      onPressed: () => state.dismissNotification(n.id),
                    ),
                  ]),
                )),
            const SizedBox(height: 16),
          ],

          // KPIs
          Wrap(spacing: 16, runSpacing: 16, children: [
            _kpi('Plannings', '${myPlannings.length}', AppColors.red,
                Icons.calendar_month_rounded),
            _kpi('Séances', '$totalSeances', const Color(0xFF3A86FF),
                Icons.event_note_rounded),
            _kpi('Volume', AppConstants.fmtMinutes(totalVol), AppColors.yellow,
                Icons.timer_rounded),
            _kpi('Joueurs', '${state.joueurs.length}', const Color(0xFF06D6A0),
                Icons.people_rounded),
          ]),
          const SizedBox(height: 32),

          // Plannings récents
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Plannings récents',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal)),
              TextButton(
                  onPressed: () {},
                  child: const Text('Voir tous',
                      style: TextStyle(color: AppColors.red))),
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
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Créer un planning',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Text('Groupe ou Spécifique',
                          style:
                              TextStyle(color: AppColors.gray, fontSize: 13)),
                    ])),
                VpButton(
                    label: 'Commencer',
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

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/planning/create'),
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : state.plannings.isEmpty
              ? _empty(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.plannings.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0)
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: const Text('Mes plannings',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.charcoal)),
                      );
                    return _PlanningCard(planning: state.plannings[i - 1]);
                  },
                ),
    );
  }

  Widget _empty(BuildContext context) => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Aucun planning',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal)),
          const SizedBox(height: 8),
          const Text('Créez votre premier planning',
              style: TextStyle(color: AppColors.gray)),
          const SizedBox(height: 24),
          VpButton(
              label: 'Créer un planning',
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
  final ctrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Une suggestion ?',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.charcoal)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Votre avis nous aide à améliorer VolleyPlan.",
              style: TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ex: "J\'aimerais pouvoir trier les joueurs par poste"',
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
            child: const Text('Plus tard')),
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
                const SnackBar(content: Text('Merci pour votre retour !')),
              );
            }
          },
          child: const Text('Envoyer'),
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
    final state = context.watch<AppState>();
    // Détection de la largeur de la fenêtre pour éviter l'overflow horizontal sur mobile
    final isNarrow = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mes joueurs',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal)),
            const SizedBox(height: 20),

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
                  const Text('Ajouter un joueur',
                      style: TextStyle(
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
                            hintText: 'Nom du joueur',
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
                          hint: const Text('Poste'),
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
                                  value: p,
                                  child: Text(p,
                                      style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) => setState(() => _posteSelected = v),
                        ),
                        const SizedBox(height: 16),
                        VpButton(
                            label: 'Ajouter le joueur',
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
                        controller: _nomCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nom du joueur',
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
                        value: _posteSelected,
                        hint: const Text('Poste'),
                        items: AppConstants.postes
                            .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _posteSelected = v),
                      ),
                      const SizedBox(width: 10),
                      VpButton(
                          label: 'Ajouter',
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
                        ? Text(j.poste!,
                            style: const TextStyle(
                                color: AppColors.gray, fontSize: 12))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.gray, size: 20),
                            onPressed: () => _showEditDialog(context, j)),
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.red, size: 20),
                            onPressed: () =>
                                _confirmDelete(context, j.id, j.nom)),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, joueur) {
    final ctrl = TextEditingController(text: joueur.nom);
    String? poste = joueur.poste;
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Modifier le joueur'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(labelText: 'Nom')),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: poste,
                  isExpanded: true,
                  hint: const Text('Poste'),
                  items: AppConstants.postes
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    poste = v;
                    (ctx as Element).markNeedsBuild();
                  },
                ),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    await context.read<AppState>().updateJoueur(
                        joueur.id, {'nom': ctrl.text, 'poste': poste});
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            ));
  }

  void _confirmDelete(BuildContext context, int id, String nom) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Supprimer le joueur'),
              content: Text(
                  'Supprimer $nom ? Il sera désactivé mais conservé dans les plannings existants.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    await context.read<AppState>().removeJoueur(id);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Supprimer'),
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
                        ? '👥 Groupe'
                        : '🎯 ${planning.poste ?? "Individuel"}',
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
              _stat('${planning.seances.length}', 'séances', AppColors.red),
              const SizedBox(width: 20),
              _stat(AppConstants.fmtMinutes(planning.volumeTotal), 'volume',
                  AppColors.charcoal),
              const SizedBox(width: 20),
              _stat(
                  '${planning.joueurs.length}', 'joueurs', AppColors.charcoal),
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
                                '${AppConstants.domaineIcon(d)} ${AppConstants.domaineLabel(d)}',
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

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bilan Global',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal)),
            const SizedBox(height: 8),
            const Text('Statistiques cumulées de l\'ensemble de vos plannings.',
                style: TextStyle(color: AppColors.gray, fontSize: 14)),
            const SizedBox(height: 32),
            if (state.loading && bilan == null)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.red))
            else if (bilan == null)
              const Center(child: Text('Aucune donnée disponible.'))
            else ...[
              // KPIs Globaux
              Wrap(spacing: 16, runSpacing: 16, children: [
                _statCard('Plannings total', '${bilan['nb_plannings']}',
                    Icons.collections_bookmark_rounded),
                _statCard('Séances total', '${bilan['nb_seances']}',
                    Icons.event_available_rounded),
                _statCard(
                    'Volume total',
                    AppConstants.fmtMinutes(bilan['total_minutes']),
                    Icons.timer_rounded),
                _statCard(
                    'Moyenne/séance',
                    AppConstants.fmtMinutes(bilan['avg_seance_minutes']),
                    Icons.av_timer_rounded),
              ]),
              const SizedBox(height: 40),

              // Répartition
              const Text('Répartition globale par domaine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                              Text(d['label'],
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
              const Text('Analyses & Conseils',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
