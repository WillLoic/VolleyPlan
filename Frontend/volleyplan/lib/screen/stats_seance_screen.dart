// lib/screen/stats_seance_screen.dart
//
// Consultation des statistiques enregistrées pendant "Exécuter la séance".
// Structure : Exercice (expandable) -> Joueur -> Domaine -> détail des champs.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/joueur.dart';
import '../models/planning.dart';
import '../services/app_state.dart';
import '../services/action_jeu_service.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../utils/action_jeu_label.dart';

class StatsSeanceScreen extends StatefulWidget {
  final int planningId;
  final int seanceId;

  const StatsSeanceScreen({
    super.key,
    required this.planningId,
    required this.seanceId,
  });

  @override
  State<StatsSeanceScreen> createState() => _StatsSeanceScreenState();
}

class _StatsSeanceScreenState extends State<StatsSeanceScreen> {
  bool _loading = true;
  String? _error;

  Planning? _planning;
  Map<String, dynamic> _statsSeance = {}; // { exercice_id(str): { joueur_id(str): {...} } }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appState = context.read<AppState>();
      final planning = await appState.loadPlanning(widget.planningId);
      final stats = await ActionJeuService.getStatsSeance(widget.seanceId);

      setState(() {
        _planning = planning;
        _statsSeance = stats;
        _loading = false;
      });

      AnalyticsService.trackEvent(
        'stats_seance_viewed',
        data: {
          'planning_id': widget.planningId,
          'seance_id': widget.seanceId,
          'exercices_with_stats': stats.length,
        },
        token: appState.token,
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Joueur? _findJoueur(int id) {
    try {
      return _planning?.joueurs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(l10n.statsSeanceTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : _error != null
              ? _buildError(l10n)
              : _buildContent(l10n),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _load, child: Text(l10n.reessayerButton)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final seance = _planning?.seances.firstWhere(
      (s) => s.id == widget.seanceId,
      orElse: () => _planning!.seances.first,
    );

    if (seance == null || _statsSeance.isEmpty) {
      return _buildEmptyState(l10n);
    }

    // On garde uniquement les exercices de cette séance qui ont des stats enregistrées
    final exercicesAvecStats = seance.exercices
        .where((ex) => _statsSeance.containsKey(ex.id.toString()))
        .toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));

    if (exercicesAvecStats.isEmpty) {
      return _buildEmptyState(l10n);
    }

    // Calcul des stats globales de la séance pour le graphe
    final Map<String, int> globalStats = {};
    for (var exStats in _statsSeance.values) {
      final exMap = exStats as Map<String, dynamic>;
      for (var playerStats in exMap.values) {
        final playerMap = playerStats as Map<String, dynamic>;
        for (var domEntry in playerMap.entries) {
          final domaine = domEntry.key;
          final data = domEntry.value as Map<String, dynamic>;
          final total = data['total'] as int? ?? 0;
          globalStats[domaine] = (globalStats[domaine] ?? 0) + total;
        }
      }
    }

    final localeCode = Localizations.localeOf(context).languageCode;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.red,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exercicesAvecStats.length + 1, // +1 pour le chart
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildGlobalRadarChart(globalStats, localeCode, l10n);
          }
          final exercice = exercicesAvecStats[index - 1];
          final statsExercice =
              _statsSeance[exercice.id.toString()] as Map<String, dynamic>;
          return _buildExerciceCard(
              exercice.nom, exercice.domaines, statsExercice, l10n);
        },
      ),
    );
  }

  Widget _buildGlobalRadarChart(Map<String, int> globalStats, String localeCode, AppLocalizations l10n) {
    if (globalStats.isEmpty) return const SizedBox.shrink();

    final domaines = globalStats.keys.toList();
    if (domaines.length < 3) return const SizedBox.shrink(); // RadarChart needs at least 3 points to look good

    return Container(
      height: 300,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(
            l10n.statsSeanceTitle, // Or any title you want
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.charcoal),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.red.withOpacity(0.2),
                    borderColor: AppColors.red,
                    entryRadius: 4,
                    dataEntries: domaines
                        .map((d) => RadarEntry(value: globalStats[d]!.toDouble()))
                        .toList(),
                    borderWidth: 2,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: AppColors.grayLight),
                titlePositionPercentageOffset: 0.25,
                getTitle: (index, angle) {
                  final domaine = domaines[index];
                  return RadarChartTitle(
                    text: ActionJeuLabels.domaineLabel(domaine, localeCode),
                    angle: 0,
                  );
                },
                tickCount: 3,
                ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
                tickBorderData: const BorderSide(color: AppColors.grayLight),
                gridBorderData: const BorderSide(color: AppColors.grayLight, width: 1.5),
              ),
              swapAnimationDuration: const Duration(milliseconds: 150),
              swapAnimationCurve: Curves.linear,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.gray),
            const SizedBox(height: 16),
            Text(l10n.aucuneStatTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text(l10n.aucuneStatMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gray)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciceCard(String titre, List<String> domaines,
      Map<String, dynamic> statsExercice, AppLocalizations l10n) {
    final localeCode = Localizations.localeOf(context).languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              children: domaines
                  .map((d) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppConstants.domaineColor(d).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(ActionJeuLabels.domaineLabel(d, localeCode),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.domaineColor(d))),
                      ))
                  .toList(),
            ),
          ),
          children: statsExercice.entries.map((entry) {
            final joueurId = int.tryParse(entry.key) ?? 0;
            final statsParDomaine = entry.value as Map<String, dynamic>;
            final joueur = _findJoueur(joueurId);
            return _buildJoueurStats(joueur?.nom ?? 'Joueur #$joueurId', statsParDomaine, localeCode);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildJoueurStats(
      String nomJoueur, Map<String, dynamic> statsParDomaine, String localeCode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grayXLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.redLight,
              child: Text(nomJoueur.isNotEmpty ? nomJoueur[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.red)),
            ),
            const SizedBox(width: 10),
            Text(nomJoueur,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          ...statsParDomaine.entries.map((domEntry) {
            final domaine = domEntry.key;
            final data = domEntry.value as Map<String, dynamic>;
            final total = data['total'] ?? 0;
            final parChamp = (data['par_champ'] as Map<String, dynamic>?) ?? {};
            final color = AppConstants.domaineColor(domaine);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ActionJeuLabels.domaineLabel(domaine, localeCode)} — $total',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  ...parChamp.entries.map((champEntry) {
                    final champ = champEntry.key;
                    final valeurs = champEntry.value as Map<String, dynamic>;
                    return _buildMiniStatChart(champ, valeurs, localeCode);
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMiniStatChart(String champ, Map<String, dynamic> valeurs, String localeCode) {
    if (valeurs.isEmpty) return const SizedBox.shrink();
    
    // Trier par valeur décroissante pour avoir les plus gros segments en premier
    final sortedEntries = valeurs.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
      
    int total = 0;
    for (var e in sortedEntries) {
      total += (e.value as num).toInt();
    }
    
    if (total == 0) return const SizedBox.shrink();

    // Palette de couleurs pour les segments du graphe
    final colors = [
      const Color(0xFF4CAF50), // Vert
      const Color(0xFFF44336), // Rouge
      const Color(0xFF2196F3), // Bleu
      const Color(0xFFFFC107), // Jaune
      const Color(0xFF9C27B0), // Violet
      const Color(0xFFFF9800), // Orange
      const Color(0xFF00BCD4), // Cyan
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ActionJeuLabels.champLabel(champ, localeCode),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.charcoal),
          ),
          const SizedBox(height: 6),
          // La barre segmentée (Graphe horizontal)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: sortedEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = (entry.value.value as num).toInt();
                  final flex = value;
                  if (flex <= 0) return const SizedBox.shrink();
                  
                  return Expanded(
                    flex: flex,
                    child: Container(
                      color: colors[index % colors.length],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // La légende
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: sortedEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final val = entry.value;
              final count = (val.value as num).toInt();
              if (count <= 0) return const SizedBox.shrink();
              
              final label = ActionJeuLabels.valeurLabel(val.key, localeCode);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$label ($count)',
                    style: const TextStyle(fontSize: 11, color: AppColors.gray),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}



//-----------------------------