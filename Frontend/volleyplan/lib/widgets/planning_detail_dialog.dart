// lib/widgets/planning_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import '../services/analytics_service.dart';
import '../services/excel_service.dart';
import 'share_planning_dialog.dart';
import '../screen/executer_seance_screen.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlanningTitle),
        content: Text(l10n.deletePlanningConfirm(_planning!.titre)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteButton),
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
            SnackBar(content: Text(l10n.planningDeletedSuccess)),
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
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.red));
    }
    if (_error != null) {
      return Center(child: Text(l10n.errorPrefix(_error!)));
    }
    if (_planning == null || _bilan == null) {
      return Center(child: Text(l10n.planningNotFound));
    }

    final appState = context.watch<AppState>();
    final isOwner =
        widget.token == null && _planning!.isOwner(appState.coach?.id);

    // Détection de la largeur disponible pour savoir si on doit empiler verticalement
    final isNarrow = MediaQuery.of(context).size.width < 750;

    return Dialog(
      backgroundColor: AppColors.offWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 1000,
            maxHeight:
                isNarrow ? MediaQuery.of(context).size.height * 0.85 : 800),
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
                child: isNarrow
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPlanningOverview(_planning!, l10n,
                                isOwner: isOwner),
                            const Divider(height: 32),
                            _buildBilanSection(_bilan!, l10n),
                            if (isOwner) ...[
                              const Divider(height: 32),
                              _buildStaffSection(isOwner, appState, l10n),
                            ],
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                                child: _buildPlanningOverview(_planning!, l10n,
                                    isOwner: isOwner)),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Column(children: [
                              Expanded(
                                  child: SingleChildScrollView(
                                      child:
                                          _buildBilanSection(_bilan!, l10n))),
                              if (isOwner) ...[
                                const Divider(height: 32),
                                _buildStaffSection(isOwner, appState, l10n),
                              ],
                            ]),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(context, isOwner, widget.token, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffSection(
      bool isOwner, AppState appState, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l10n.staffCollaborationTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                          content: Text(l10n.inviteSentSuccess(email))));
                    }
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l10n.errorPrefix(e.toString())),
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
                              SnackBar(
                                  content:
                                      Text(l10n.collaboratorRemovedSuccess)),
                            );
                          }
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(l10n.errorPrefix(e.toString())),
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
        Text(l10n.noCollaborators,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray,
                fontStyle: FontStyle.italic)),
    ]);
  }

  Widget _buildPlanningOverview(Planning planning, AppLocalizations l10n,
      {bool isOwner = false}) {
    String getDurationLabel(String d) {
      switch (d.toLowerCase()) {
        case 'hebdomadaire':
          return l10n.planningFormDurationWeekly;
        case 'mensuel':
          return l10n.planningFormDurationMonthly;
        case 'trimestriel':
          return l10n.planningFormDurationQuarterly;
        case 'semestriel':
          return l10n.planningFormDurationHalfYearly;
        case 'annuel':
          return l10n.planningFormDurationYearly;
        default:
          return d;
      }
    }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.planningOverviewTitle,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal)),
        const SizedBox(height: 16),
        _detailRow(
            l10n.labelMode,
            planning.mode == 'groupe'
                ? '${l10n.modeGroup} 👥'
                : '${l10n.modeSpecific} 🎯'),
        if (planning.mode == 'individuel' && planning.poste != null)
          _detailRow(l10n.labelPostes, planning.poste!),
        _detailRow(l10n.labelDuration, getDurationLabel(planning.duree)),
        if (planning.dateDebut != null)
          _detailRow(
              l10n.labelStart,
              DateFormat('dd/MM/yyyy')
                  .format(DateTime.parse(planning.dateDebut!))),
        if (planning.dateFin != null)
          _detailRow(
              l10n.labelEnd,
              DateFormat('dd/MM/yyyy')
                  .format(DateTime.parse(planning.dateFin!))),
        _detailRow(l10n.labelNbSessions, '${planning.nbSeances}'),
        _detailRow(
            l10n.labelPlayersInvolved,
            planning.joueurs.isNotEmpty
                ? planning.joueurs.map((j) => j.nom).join(', ')
                : l10n.labelNone),
        const SizedBox(height: 16),
        Text(l10n.labelSessions,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal)),
        const SizedBox(height: 8),
        if (planning.seances.isEmpty)
          Text(l10n.noSessionsDefined,
              style: const TextStyle(color: AppColors.gray)),
        ...planning.seances
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.sessionIndexLabel(s.ordre + 1, s.titre),
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
                            if (s.heureDebut != null)
                              l10n.atTime(s.heureDebut!),
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

                      // ── NOUVEAU : Bouton "Noter les absences" ──────────────
                      if (isOwner && s.id != null) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context); // Ferme le dialog
                            context.push('/presence/${s.id}');
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.red.withOpacity(0.25),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.how_to_reg_rounded,
                                    size: 14, color: AppColors.red),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.markAttendance, // ou texte direct si pas encore dans l10n
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ── FIN NOUVEAU ───────────────────────────────────────
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExecuterSeanceScreen(
                                  planningId: widget.planningId,
                                  seanceId: s.id!,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06D6A0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      const Color(0xFF06D6A0).withOpacity(0.3),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_circle_outline_rounded,
                                    size: 14, color: Color(0xFF06D6A0)),
                                const SizedBox(width: 6),
                                Text(l10n.executerSeanceButton,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF06D6A0),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildBilanSection(Map<String, dynamic> bilan, AppLocalizations l10n) {
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

    // Traduction intelligente des recommandations du backend
    String translateRec(String text) {
      if (l10n.localeName == 'fr') return text; // Déjà en FR

      // Mapping manuel pour la Beta si le backend n'envoie pas d'IDs
      if (text.contains("représente")) {
        final parts = text.split(" représente ");
        final pct = parts[1].split("%")[0];
        return "${getDomaineLabel(parts[0])} represents $pct% of the volume — consider diversifying.";
      }
      if (text.contains("peu travaillé")) {
        final domain = text.split(" peu travaillé")[0];
        return "${getDomaineLabel(domain)} is rarely worked on — needs strengthening?";
      }
      if (text.contains("Aucune séance physique planifiée")) {
        return "No physical session planned — think about integrating strength or endurance.";
      }
      if (text.contains("Durée moyenne de")) {
        return text
            .replaceAll("Durée moyenne de", "Average duration of")
            .replaceAll("min/séance — séances courtes, vérifiez la densité.",
                "min/session — short sessions, check density.");
      }
      if (text.contains("Séances longues")) {
        return text.replaceAll("Séances longues", "Long sessions").replaceAll(
            "en moy. — surveillez la récupération des joueurs.",
            "avg. — monitor player recovery.");
      }
      if (text.contains("Planning bien équilibré")) {
        return "Well-balanced schedule — good area distribution!";
      }
      return text;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.planningBilanTitle,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal)),
        const SizedBox(height: 16),
        _bilanStat(l10n.labelNbSessions, '${bilan['nb_seances']}'),
        _bilanStat(l10n.labelTotalVolume,
            AppConstants.fmtMinutes(bilan['total_minutes'])),
        _bilanStat(l10n.labelAvgDurationPerSession,
            AppConstants.fmtMinutes(bilan['avg_seance_minutes'])),
        const SizedBox(height: 16),
        Text(l10n.distributionByDomainTitle,
            style: const TextStyle(
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
                    child: Text(getDomaineLabel(d['id']),
                        style: const TextStyle(fontSize: 13))),
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
        Text(l10n.recommendationsTitle,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal)),
        const SizedBox(height: 8),
        if ((bilan['recommandations'] as List).isEmpty)
          Text(l10n.noSpecificRecommendations,
              style: const TextStyle(color: AppColors.gray)),
        ...(bilan['recommandations'] as List)
            .map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${translateRec(rec)}',
                      style: const TextStyle(fontSize: 13)),
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
          // L'Expanded empêche le texte de pousser et de faire déborder la Row
          Expanded(
            child: Text('$label :',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.charcoal),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isOwner, String? token,
      AppLocalizations l10n) {
    final appState = context.read<AppState>();
    // Remplacement du Row par un Wrap pour la responsivité des boutons
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        /*if (isOwner)
          VpButton(
            label: l10n.exportPdfAction,
            icon: Icons.picture_as_pdf,
            variant: VpButtonVariant.ghost,
            onPressed: () async {
              try {
                await PdfService.downloadPlanningPdf(widget.planningId);
                AnalyticsService.trackEvent('pdf_exported',
                    data: {
                      'planning_id': widget.planningId,
                      'is_owner': isOwner,
                    },
                    token: appState.token);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pdfExportSuccess)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.errorPrefix(e.toString())),
                        backgroundColor: AppColors.red),
                  );
                }
              }
            },
          ),*/
        // ── Bouton Exporter (PDF + Excel fusionnés) ──────────────────
        VpButton(
          label: l10n.exportAction,
          icon: Icons.download_rounded,
          /*variant: VpButtonVariant.ghost,
          onPressed: () async {
            try {
              await ExcelService.downloadPlanningExcel(widget.planningId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.excelExportSuccess)),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.errorPrefix(e.toString())),
                      backgroundColor: AppColors.red),
                );
              }
            }
          },*/
          onPressed: () =>
              _showExportBottomSheet(context, l10n, appState, isOwner),
        ),
        VpButton(
          label: l10n.editAction,
          icon: Icons.edit,
          onPressed: () {
            final route = token != null
                ? '/planning/${widget.planningId}?token=$token'
                : '/planning/${widget.planningId}';

            Navigator.of(context).pop();
            context.push(route);
          },
        ),
        if (isOwner) ...[
          VpButton(
            label: l10n.deleteButton,
            icon: Icons.delete,
            variant: VpButtonVariant.danger,
            onPressed: _confirmDelete,
          ),
          VpButton(
            label: l10n.sharePlanningAction,
            icon: Icons.share_rounded,
            variant: VpButtonVariant.ghost,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) =>
                    SharePlanningDialog(planningId: widget.planningId),
              );
            },
          ),
        ],
      ],
    );
  }

  void _showExportBottomSheet(BuildContext context, AppLocalizations l10n,
      AppState appState, bool isOwner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExportBottomSheet(
        planningId: widget.planningId,
        isOwner: isOwner,
        l10n: l10n,
        appState: appState,
      ),
    );
  }
}

// ── Bottom sheet d'export — widget statefull isolé ──────────────────────────
class _ExportBottomSheet extends StatefulWidget {
  final int planningId;
  final bool isOwner;
  final AppLocalizations l10n;
  final AppState appState;

  const _ExportBottomSheet({
    required this.planningId,
    required this.isOwner,
    required this.l10n,
    required this.appState,
  });
  @override
  State<_ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<_ExportBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _loadingPdf = false;
  bool _loadingExcel = false;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf() async {
    setState(() => _loadingPdf = true);
    try {
      await PdfService.downloadPlanningPdf(widget.planningId);
      AnalyticsService.trackEvent(
        'pdf_exported',
        data: {'planning_id': widget.planningId, 'is_owner': widget.isOwner},
        token: widget.appState.token,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.pdfExportSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.l10n.errorPrefix(e.toString())),
              backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _loadingExcel = true);
    try {
      await ExcelService.downloadPlanningExcel(widget.planningId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.excelExportSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingExcel = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.l10n.errorPrefix(e.toString())),
              backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loadingPdf || _loadingExcel;
    return ScaleTransition(
      scale: _scaleAnim,
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ─────────────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_rounded,
                    color: AppColors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.l10n.exportAction,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.charcoal)),
                Text(widget.l10n.exportChooseFormat,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.gray)),
              ]),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.gray, size: 20),
                onPressed: busy ? null : () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // ── Carte PDF ────────────────────────────────────────────
            _buildFormatCard(
              color: const Color(0xFFE53E3E),
              bgColor: const Color(0xFFFFF5F5),
              icon: Icons.picture_as_pdf_rounded,
              title: 'PDF',
              subtitle: widget.l10n.exportPdfDesc,
              loading: _loadingPdf,
              disabled: busy,
              onTap: _exportPdf,
            ),
            const SizedBox(height: 12),
            // ── Carte Excel ──────────────────────────────────────────
            _buildFormatCard(
              color: const Color(0xFF1D6F42),
              bgColor: const Color(0xFFF0FFF4),
              icon: Icons.table_chart_rounded,
              title: 'Excel',
              subtitle: widget.l10n.exportExcelDesc,
              loading: _loadingExcel,
              disabled: busy,
              onTap: _exportExcel,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard({
    required Color color,
    required Color bgColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool loading,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled && !loading ? 0.5 : 1.0,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: color),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray)),
                  ],
                ),
              ),
              if (!loading)
                Icon(Icons.chevron_right_rounded,
                    color: color.withValues(alpha: 0.6)),
            ]),
          ),
        ),
      ),
    );
  }
}





//-------------------------------------------------------
//on regle la responsivite de la popo up de l'apercu du planning