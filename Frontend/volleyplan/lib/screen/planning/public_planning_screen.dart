import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/analytics_service.dart';
import '../../services/partage_service.dart';
import '../../utils/constants.dart';
import '../../widgets/domaine_chip.dart';
import '../../widgets/vp_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PublicPlanningScreen extends StatefulWidget {
  final String token;

  const PublicPlanningScreen({super.key, required this.token});

  @override
  State<PublicPlanningScreen> createState() => _PublicPlanningScreenState();
}

class _PublicPlanningScreenState extends State<PublicPlanningScreen> {
  bool _loading = true;
  Map<String, dynamic>? _planning;
  String? _error;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await PartageService.getPlanningPublic(widget.token);
      if (res['success'] == true) {
        AnalyticsService.trackEvent(
          'public_planning_viewed',
          data: {
            'planning_id': res['planning']?['id'],
            'token_prefix': widget.token.length > 8
                ? widget.token.substring(0, 8)
                : widget.token,
          },
        );
        setState(() {
          _planning = res['planning'];
          _loading = false;
        });
      } else {
        AnalyticsService.trackEvent(
          'public_planning_expired_viewed',
          data: {
            'token_prefix': widget.token.length > 8
                ? widget.token.substring(0, 8)
                : widget.token,
            'reason': res['message'] ?? 'expired',
          },
        );
        setState(() {
          _error = res['message'] ?? 'Lien invalide';
          _expired = true;
          _loading = false;
        });
      }
    } catch (e) {
      AnalyticsService.trackEvent(
        'public_planning_expired_viewed',
        data: {
          'token_prefix': widget.token.length > 8
              ? widget.token.substring(0, 8)
              : widget.token,
          'reason': 'error',
        },
      );
      setState(() {
        _error = 'Ce lien a expiré ou est invalide';
        _expired = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.red, AppColors.yellow]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('🏐', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          const Text('VolleyPlan',
              style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w900)),
        ]),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : _expired
              ? _buildExpiredView()
              : _buildPlanningView(),
    );
  }

  Widget _buildExpiredView() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off_rounded, size: 60, color: AppColors.gray),
            const SizedBox(height: 20),
            Text(_error ?? l10n.publicLinkExpiredTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              l10n.publicLinkExpiredSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray),
            ),
            const SizedBox(height: 24),
            VpButton(
              label: l10n.publicDiscoverButton,
              onPressed: () {
                AnalyticsService.trackEvent(
                  'public_discover_cta_clicked',
                  data: {'source': 'expired_view'},
                );
                context.go('/register');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningView() {
    final l10n = AppLocalizations.of(context)!;
    final p = _planning!;
    final seances = (p['seances'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('👁️ ${l10n.publicViewBadge}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Text(p['titre'] ?? '',
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.charcoal)),
          const SizedBox(height: 4),
          Text(l10n.publicPlanningSessionsCount(seances.length, p['duree'] ?? ''),
              style: const TextStyle(color: AppColors.gray)),
          const SizedBox(height: 24),
          ...seances.map((s) => _buildSeanceCard(s)),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(l10n.publicCreatedWith,
                    style: TextStyle(color: AppColors.gray, fontSize: 13)),
                const SizedBox(height: 8),
                VpButton(
                  label: l10n.publicDiscoverButton,
                  small: true,
                  onPressed: () {
                    AnalyticsService.trackEvent(
                      'public_discover_cta_clicked',
                      data: {
                        'source': 'planning_view',
                        'planning_id': _planning?['id'],
                      },
                    );
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeanceCard(Map<String, dynamic> s) {
    final domaines = (s['domaines'] as List?) ?? [];
    final exercices = (s['exercices'] as List?) ?? [];

    String dateTxt = '';
    if (s['date_seance'] != null) {
      try {
        dateTxt = DateFormat('dd/MM/yyyy').format(DateTime.parse(s['date_seance']));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s['titre'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          if (dateTxt.isNotEmpty || s['heure_debut'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$dateTxt ${s['heure_debut'] ?? ''}'.trim(),
                style: const TextStyle(fontSize: 12, color: AppColors.gray),
              ),
            ),
          if (domaines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 4,
                children: domaines
                    .map((d) => DomaineChip(domaineId: d, selected: true, onTap: () {}))
                    .toList(),
              ),
            ),
          if (exercices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: exercices
                    .map<Widget>((e) => Text('• ${e['nom']} (${e['duree']}min)',
                        style: const TextStyle(fontSize: 13)))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}