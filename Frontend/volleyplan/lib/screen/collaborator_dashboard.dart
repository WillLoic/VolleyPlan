// lib/screen/collaborator_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/invitation_service.dart';
import '../utils/constants.dart';
//import '../widgets/vp_button.dart';
import '../widgets/planning_detail_dialog.dart';
import '../models/planning.dart';

class CollaboratorDashboard extends StatefulWidget {
  final String? token;
  const CollaboratorDashboard({super.key, this.token});

  @override
  State<CollaboratorDashboard> createState() => _CollaboratorDashboardState();
}

class _CollaboratorDashboardState extends State<CollaboratorDashboard> {
  Planning? _specificPlanning;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) _loadPlanning();
  }

  Future<void> _loadPlanning() async {
    setState(() => _loading = true);
    try {
      final p = await InvitationService.getPlanningByToken(widget.token!);
      setState(() => _specificPlanning = p);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorPrefix(e.toString()))));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;

    List<Planning> displayList =
        state.plannings.where((p) => !p.isOwner(state.coach?.id)).toList();

    // Si on a chargé un planning via token et qu'il n'est pas déjà dans la liste
    if (_specificPlanning != null &&
        !displayList.any((p) => p.id == _specificPlanning!.id)) {
      displayList.insert(0, _specificPlanning!);
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(l10n.collabDashboardTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                state.logout();
                context.go('/login');
              }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.collabSharedPlannings,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(l10n.collabSharedSubtitle,
                      style:
                          const TextStyle(color: AppColors.gray, fontSize: 13)),
                  const SizedBox(height: 24),
                  if (displayList.isEmpty)
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(l10n.collabNoActive,
                          style: const TextStyle(color: AppColors.gray)),
                    ))
                  else
                    ...displayList.map((p) => _CollaboratorPlanningCard(
                        planning: p, token: widget.token)),
                ],
              ),
            ),
    );
  }
}

class _CollaboratorPlanningCard extends StatelessWidget {
  //final dynamic planning;
  final Planning planning;
  final String? token;
  const _CollaboratorPlanningCard({required this.planning, this.token});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
          context: context,
          builder: (ctx) =>
              PlanningDetailDialog(planningId: planning.id, token: token)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grayLight)),
        child: Row(children: [
          const Icon(Icons.people_alt, color: AppColors.red),
          const SizedBox(width: 16),
          Expanded(
              child: Text(planning.titre,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          const Icon(Icons.chevron_right, color: AppColors.gray),
        ]),
      ),
    );
  }
}
