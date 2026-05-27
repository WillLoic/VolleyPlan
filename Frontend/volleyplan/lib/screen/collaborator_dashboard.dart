// lib/screen/collaborator_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    List<Planning> displayList = state.plannings.where((p) => !p.isOwner(state.coach?.id)).toList();
    
    // Si on a chargé un planning via token et qu'il n'est pas déjà dans la liste
    if (_specificPlanning != null && !displayList.any((p) => p.id == _specificPlanning!.id)) {
      displayList.insert(0, _specificPlanning!);
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Mes Collaborations',
            style: TextStyle(fontWeight: FontWeight.w800)),
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
            const Text('Plannings partagés avec vous',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
                'Vous pouvez consulter et modifier les séances de ces plannings.',
                style: TextStyle(color: AppColors.gray, fontSize: 13)),
            const SizedBox(height: 24),
            if (displayList.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('Aucune collaboration active pour le moment.',
                    style: TextStyle(color: AppColors.gray)),
              ))
            else
              ...displayList.map((p) => _CollaboratorPlanningCard(planning: p, token: widget.token)),
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
          builder: (ctx) => PlanningDetailDialog(
              planningId: planning.id, token: token)),
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
