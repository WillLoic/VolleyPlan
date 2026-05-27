// lib/widgets/planning_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/planning.dart';
import '../utils/constants.dart';
import '../widgets/vp_button.dart';
import '../widgets/domaine_chip.dart';
//import '../services/bilan_service.dart';
import '../services/pdf_service.dart';
import '../services/planning_service.dart';
import '../widgets/invite_collaborator_dialog.dart';

class PlanningDetailDialog extends StatefulWidget {
  final int planningId;
  final String? token;

  const PlanningDetailDialog({super.key, required this.planningId, this.token});

  @override
  State<PlanningDetailDialog> createState() => _PlanningDetailDialogState();
}

class _PlanningDetailDialogState extends State<PlanningDetailDialog> {
  Planning? _planning;
  Map<String, dynamic>? _bilan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlanningDetails();
  }

  Future<void> _loadPlanningDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appState = context.read<AppState>();
      // Charge le planning avec tous les détails (séances et exercices)
      _planning =
          await appState.loadPlanning(widget.planningId, token: widget.token);
      // Charge le bilan
      _bilan = await PlanningService.getBilan(widget.planningId,
          token: widget.token);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le planning'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer le planning "${_planning!.titre}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<AppState>().deletePlanning(widget.planningId);
        if (mounted) {
          Navigator.pop(context); // Ferme ce dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Planning supprimé avec succès !')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur lors de la suppression: $e'),
                backgroundColor: AppColors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.red));
    }
    if (_error != null) {
      return Center(child: Text('Erreur: $_error'));
    }
    if (_planning == null || _bilan == null) {
      return const Center(child: Text('Planning ou bilan introuvable.'));
    }

    final appState = context.watch<AppState>();
    // Si on a un token, on est forcément collaborateur, même si on est loggué avec le même compte
    final isOwner =
        widget.token == null && _planning!.isOwner(appState.coach?.id);

    return Dialog(
      backgroundColor: AppColors.offWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _planning!.titre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.charcoal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.gray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                          child: _buildPlanningOverview(_planning!)),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(children: [
                        Expanded(
                            child: SingleChildScrollView(
                                child: _buildBilanSection(_bilan!))),
                        if (isOwner) ...[
                          const Divider(height: 32),
                          _buildStaffSection(isOwner, appState),
                        ],
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(context, isOwner, widget.token),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffSection(bool isOwner, AppState appState) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Staff / Collaboration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.person_add_alt_1,
                color: AppColors.red, size: 20),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (ctx) =>
                    InviteCollaboratorDialog(onInvite: (email) async {
                  try {
                    await appState.inviteCollaborator(_planning!.id, email);
                    if (mounted) {
                      // Mise à jour de l'aperçu local avec les nouvelles données du staff
                      final updated = appState.plannings
                          .firstWhere((p) => p.id == _planning!.id);
                      setState(() => _planning = updated);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Invitation envoyée à $email')));
                    }
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: AppColors.red));
                  }
                }),
              );
            },
          ),
      ]),
      const SizedBox(height: 8),
      ..._planning!.staff
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(
                      c.status == 'pending'
                          ? Icons.mail_outline
                          : Icons.check_circle_outline,
                      size: 14,
                      color: c.status == 'pending'
                          ? AppColors.gray
                          : Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(c.email,
                          style: TextStyle(
                              fontSize: 12,
                              color: c.status == 'pending'
                                  ? AppColors.gray
                                  : AppColors.charcoal))),
                  if (isOwner)
                    InkWell(
                      onTap: () async {
                        try {
                          await appState.removeCollaborator(
                              _planning!.id, c.email);
                          if (mounted) {
                            // On récupère la version à jour du planning depuis l'état global
                            final updated = appState.plannings
                                .firstWhere((p) => p.id == _planning!.id);
                            setState(() => _planning = updated);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Collaborateur retiré avec succès')),
                            );
                          }
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Erreur lors du retrait : $e'),
                                backgroundColor: AppColors.red));
                        }
                      },
                      child: const Icon(Icons.remove_circle_outline,
                          size: 14, color: AppColors.red),
                    ),
                ]),
              ))
          .toList(),
      if (_planning!.staff.isEmpty)
        const Text('Aucun collaborateur invité.',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.gray,
                fontStyle: FontStyle.italic)),
    ]);
  }

  Widget _buildPlanningOverview(Planning planning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aperçu du planning',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal)),
        const SizedBox(height: 16),
        _detailRow(
            'Mode', planning.mode == 'groupe' ? 'Groupe 👥' : 'Spécifique 🎯'),
        if (planning.mode == 'individuel' && planning.poste != null)
          _detailRow('Poste(s)', planning.poste!),
        _detailRow('Durée',
            planning.duree[0].toUpperCase() + planning.duree.substring(1)),
        if (planning.dateDebut != null)
          _detailRow(
              'Début',
              DateFormat('dd/MM/yyyy')
                  .format(DateTime.parse(planning.dateDebut!))),
        if (planning.dateFin != null)
          _detailRow(
              'Fin',
              DateFormat('dd/MM/yyyy')
                  .format(DateTime.parse(planning.dateFin!))),
        _detailRow('Nombre de séances', '${planning.nbSeances}'),
        _detailRow(
            'Joueurs concernés',
            planning.joueurs.isNotEmpty
                ? planning.joueurs.map((j) => j.nom).join(', ')
                : 'Aucun'),
        const SizedBox(height: 16),
        const Text('Séances',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal)),
        const SizedBox(height: 8),
        if (planning.seances.isEmpty)
          const Text('Aucune séance définie.',
              style: TextStyle(color: AppColors.gray)),
        ...planning.seances
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Séance ${s.ordre + 1} : ${s.titre}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (s.dateSeance != null ||
                          s.heureDebut != null ||
                          s.lieu != null) ...[
                        Builder(builder: (context) {
                          String datePart = '';
                          if (s.dateSeance != null) {
                            try {
                              datePart = DateFormat('dd/MM/yyyy')
                                  .format(DateTime.parse(s.dateSeance!));
                            } catch (_) {
                              datePart = s.dateSeance!;
                            }
                          }

                          final info = [
                            datePart,
                            if (s.heureDebut != null) 'à ${s.heureDebut}',
                            if (s.lieu != null) '(${s.lieu})',
                          ].join(' ').trim();

                          return Text(info,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.gray));
                        }),
                      ],
                      if (s.domaines.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: s.domaines
                              .map((d) => DomaineChip(
                                  domaineId: d, selected: true, onTap: () {}))
                              .toList(),
                        ),
                      if (s.exercices.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: s.exercices
                                .map((ex) => Text(
                                    '• ${ex.nom} (${ex.duree}min)',
                                    style: const TextStyle(fontSize: 12)))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label :',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.charcoal)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.gray)),
          ),
        ],
      ),
    );
  }

  Widget _buildBilanSection(Map<String, dynamic> bilan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bilan du planning',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal)),
        const SizedBox(height: 16),
        _bilanStat('Nombre de séances', '${bilan['nb_seances']}'),
        _bilanStat(
            'Volume total', AppConstants.fmtMinutes(bilan['total_minutes'])),
        _bilanStat('Durée moy./séance',
            AppConstants.fmtMinutes(bilan['avg_seance_minutes'])),
        const SizedBox(height: 16),
        const Text('Répartition par domaine',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal)),
        const SizedBox(height: 8),
        ...(bilan['domain_stats'] as List).map((d) {
          if (d['minutes'] == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                    width: 80,
                    child:
                        Text(d['label'], style: const TextStyle(fontSize: 13))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: d['pct'] / 100,
                    backgroundColor: AppColors.grayLight,
                    color: AppConstants.domaineColor(d['id']),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${d['pct']}%', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        const Text('Recommandations',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal)),
        const SizedBox(height: 8),
        if ((bilan['recommandations'] as List).isEmpty)
          const Text('Aucune recommandation spécifique.',
              style: TextStyle(color: AppColors.gray)),
        ...(bilan['recommandations'] as List)
            .map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $rec', style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
      ],
    );
  }

  Widget _bilanStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label :',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.charcoal)),
          Text(value, style: const TextStyle(color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, bool isOwner, String? token) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isOwner)
          VpButton(
            label: 'Exporter PDF',
            icon: Icons.picture_as_pdf,
            variant: VpButtonVariant.ghost,
            onPressed: () async {
              try {
                await PdfService.downloadPlanningPdf(widget.planningId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF généré et téléchargé !')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erreur lors de l\'export PDF: $e'),
                        backgroundColor: AppColors.red),
                  );
                }
              }
            },
          ),
        const SizedBox(width: 12),
        VpButton(
          label: 'Modifier',
          icon: Icons.edit,
          onPressed: () {
            final route = token != null
                ? '/planning/${widget.planningId}?token=$token'
                : '/planning/${widget.planningId}';

            // On ferme d'abord la pop-up proprement
            Navigator.of(context).pop();
            // Puis on navigue en utilisant le router lié au context racine
            context.push(route);
          },
        ),
        if (isOwner) ...[
          const SizedBox(width: 12),
          VpButton(
            label: 'Supprimer',
            icon: Icons.delete,
            variant: VpButtonVariant.danger,
            onPressed: _confirmDelete,
          ),
        ],
      ],
    );
  }
}
