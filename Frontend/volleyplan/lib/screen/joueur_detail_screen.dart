import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class JoueurDetailScreen extends StatefulWidget {
  final int joueurId;

  const JoueurDetailScreen({super.key, required this.joueurId});

  @override
  State<JoueurDetailScreen> createState() => _JoueurDetailScreenState();
}

class _JoueurDetailScreenState extends State<JoueurDetailScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _statsData;
  Map<String, dynamic>? _radarData;

  final List<String> _domains = [
    'service',
    'reception',
    'passe',
    'attaque',
    'block',
    'defense',
    'physique',
    'general'
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/stats/joueur/${widget.joueurId}'),
        ApiService.get('/stats/joueur/${widget.joueurId}/radar'),
      ]);

      if (results[0]['success'] == true && results[1]['success'] == true) {
        _statsData = results[0];
        _radarData = results[1];
      } else {
        _error = results[0]['message'] ?? results[1]['message'] ?? 'Erreur lors de la récupération';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playerProfile),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
      ),
      backgroundColor: AppColors.offWhite,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : _error != null
              ? _buildErrorView()
              : _buildContent(l10n),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.red),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Erreur',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.charcoal),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStats,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final j = _statsData?['joueur'] ?? {};
    final double presenceRate = (_statsData?['taux_presence'] ?? 100.0).toDouble();
    final int plannedSessions = _statsData?['nb_seances_prevues'] ?? 0;
    final int realSessions = _statsData?['nb_seances_reelles'] ?? 0;
    
    // Volume total prévu/réel
    final plannedVolMap = _statsData?['volume_prevu_par_domaine'] ?? {};
    final realVolMap = _statsData?['volume_reel_par_domaine'] ?? {};
    final double plannedVolTotal = plannedVolMap.values.fold(0.0, (sum, item) => sum + (item ?? 0));
    final double realVolTotal = realVolMap.values.fold(0.0, (sum, item) => sum + (item ?? 0));

    String getPosteLabel(String p) {
      switch (p) {
        case 'Passeur': return l10n.postePasseur;
        case 'Libéro': return l10n.posteLibero;
        case 'Central': return l10n.posteCentral;
        case 'Pointu': return l10n.postePointu;
        case 'Réceptionneur-Attaquant': return l10n.posteReceptionneurAttaquant;
        case 'Universal': return l10n.posteUniversal;
        default: return p;
      }
    }

    String getDomaineLabel(String id) {
      switch (id.toLowerCase()) {
        case 'service': return l10n.domaineService;
        case 'reception': return l10n.domaineReception;
        case 'passe': return l10n.domainePasse;
        case 'attaque': return l10n.domaineAttaque;
        case 'block': return l10n.domaineBlock;
        case 'defense': return l10n.domaineDefense;
        case 'physique': return l10n.domainePhysique;
        case 'general': return l10n.domaineGeneral;
        default: return id;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête joueur
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.redLight,
                  child: Text(
                    j['nom'] != null && j['nom'].isNotEmpty ? j['nom'][0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        j['nom'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (j['poste'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.grayXLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            getPosteLabel(j['poste']),
                            style: const TextStyle(
                              color: AppColors.charcoal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPIs Clés
          LayoutBuilder(builder: (context, constraints) {
            final double cardWidth = (constraints.maxWidth - 20) / 2;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                // KPI Taux de présence
                _buildKpiCard(
                  width: cardWidth,
                  title: l10n.attendanceRate,
                  value: '$presenceRate%',
                  icon: Icons.star_border,
                  color: AppColors.red,
                  child: SizedBox(
                    height: 12,
                    child: LinearProgressIndicator(
                      value: presenceRate / 100,
                      backgroundColor: AppColors.grayLight,
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // KPI Séances (Réelles vs Prévues)
                _buildKpiCard(
                  width: cardWidth,
                  title: l10n.labelSessions,
                  value: '$realSessions / $plannedSessions',
                  icon: Icons.calendar_today,
                  color: Colors.green,
                  child: Text(
                    '${l10n.seancesAttended} / ${l10n.seancesPlanned}',
                    style: const TextStyle(fontSize: 11, color: AppColors.gray),
                  ),
                ),
                // KPI Volume prévu
                _buildKpiCard(
                  width: cardWidth,
                  title: l10n.plannedVolume,
                  value: AppConstants.fmtMinutes(plannedVolTotal.toInt()),
                  icon: Icons.hourglass_empty,
                  color: AppColors.gray,
                ),
                // KPI Volume réel
                _buildKpiCard(
                  width: cardWidth,
                  title: l10n.realVolume,
                  value: AppConstants.fmtMinutes(realVolTotal.toInt()),
                  icon: Icons.hourglass_full,
                  color: Colors.blue,
                ),
              ],
            );
          }),
          const SizedBox(height: 20),

          // Graphique Radar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.playerStats,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.realVolume} vs ${l10n.teamAverage}',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray),
                ),
                const SizedBox(height: 20),
                
                // Légende
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(l10n.realVolume, AppColors.red.withOpacity(0.6)),
                    const SizedBox(width: 20),
                    _buildLegendItem(l10n.teamAverage, Colors.blue.withOpacity(0.6)),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Graphe Radar
                SizedBox(
                  height: 300,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: _buildRadarDataSets(),
                      radarBorderData: const BorderSide(color: AppColors.grayLight, width: 1),
                      gridBorderData: const BorderSide(color: AppColors.grayLight, width: 0.5),
                      tickBorderData: const BorderSide(color: AppColors.grayLight, width: 0.5),
                      ticksTextStyle: const TextStyle(color: AppColors.gray, fontSize: 9),
                      titlePositionPercentageOffset: 0.15,
                      titleTextStyle: const TextStyle(color: AppColors.charcoal, fontSize: 10, fontWeight: FontWeight.bold),
                      getTitle: (index, angle) {
                        return RadarChartTitle(text: getDomaineLabel(_domains[index]));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Détail par domaine (volume prévu vs réel)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.distributionByDomainTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                ..._domains.map((dom) {
                  final double planned = (plannedVolMap[dom] ?? 0).toDouble();
                  final double real = (realVolMap[dom] ?? 0).toDouble();

                  if (planned == 0 && real == 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppConstants.domaineIcon(dom) + ' ' + getDomaineLabel(dom),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${AppConstants.fmtMinutes(real.toInt())} / ${AppConstants.fmtMinutes(planned.toInt())}',
                              style: const TextStyle(fontSize: 12, color: AppColors.gray),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Barre de progression réelle
                        Stack(
                          children: [
                            // Prévu (Fond gris)
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.grayXLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            // Prévu (Grosse barre de couleur claire)
                            if (planned > 0)
                              FractionallySizedBox(
                                widthFactor: 1.0,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppConstants.domaineColor(dom).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            // Réel (Barre de couleur pleine)
                            if (planned > 0 && real > 0)
                              FractionallySizedBox(
                                widthFactor: (real / planned).clamp(0.0, 1.0),
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppConstants.domaineColor(dom),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<RadarDataSet> _buildRadarDataSets() {
    final playerVolMap = _radarData?['volume_reel'] ?? {};
    final teamVolMap = _radarData?['moyenne_equipe'] ?? {};

    // Trouver le maximum pour normaliser les valeurs sur une échelle de radar propre
    double maxVal = 10.0;
    for (var d in _domains) {
      final double pv = (playerVolMap[d] ?? 0.0).toDouble();
      final double tv = (teamVolMap[d] ?? 0.0).toDouble();
      if (pv > maxVal) maxVal = pv;
      if (tv > maxVal) maxVal = tv;
    }

    final List<RadarEntry> playerEntries = [];
    final List<RadarEntry> teamEntries = [];

    for (var d in _domains) {
      playerEntries.add(RadarEntry(value: (playerVolMap[d] ?? 0.0).toDouble()));
      teamEntries.add(RadarEntry(value: (teamVolMap[d] ?? 0.0).toDouble()));
    }

    return [
      // Dataset joueur
      RadarDataSet(
        fillColor: AppColors.red.withOpacity(0.25),
        borderColor: AppColors.red,
        entryRadius: 3,
        borderWidth: 2,
        dataEntries: playerEntries,
      ),
      // Dataset équipe
      RadarDataSet(
        fillColor: Colors.blue.withOpacity(0.15),
        borderColor: Colors.blue,
        entryRadius: 3,
        borderWidth: 2,
        dataEntries: teamEntries,
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.8), width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.charcoal),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Widget? child,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.gray, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: color.withOpacity(0.8), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.charcoal,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 8),
            child,
          ],
        ],
      ),
    );
  }
}
