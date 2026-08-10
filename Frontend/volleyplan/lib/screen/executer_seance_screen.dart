// lib/screen/executer_seance_screen.dart
//
// Point d'entrée du système de statistiques de jeu.
// Liste les exercices d'une séance dans l'ordre, permet de naviguer vers
// la saisie de chacun, et affiche leur statut (à faire / terminé).

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/exercice.dart';
import '../models/planning.dart';
import '../models/seance.dart';
import '../services/app_state.dart';
import '../services/action_jeu_service.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../utils/action_jeu_label.dart';
import '../widgets/action_saisie_form.dart';
import 'stats_seance_screen.dart';

class ExecuterSeanceScreen extends StatefulWidget {
  final int planningId;
  final int seanceId;

  const ExecuterSeanceScreen({
    super.key,
    required this.planningId,
    required this.seanceId,
  });

  @override
  State<ExecuterSeanceScreen> createState() => _ExecuterSeanceScreenState();
}

class _ExecuterSeanceScreenState extends State<ExecuterSeanceScreen> {
  bool _loading = true;
  String? _error;

  Planning? _planning;
  Seance? _seance;

  // Statut local des exercices : true = terminé (a des actions enregistrées)
  final Map<int, bool> _exercicesTermines = {};

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

      if (planning == null) {
        setState(() {
          _error = 'Planning introuvable';
          _loading = false;
        });
        return;
      }

      final seance = planning.seances.firstWhere(
        (s) => s.id == widget.seanceId,
        orElse: () => planning.seances.first,
      );

      // Vérifie quels exercices ont déjà des stats enregistrées (résilience
      // si le coach quitte l'écran et revient plus tard dans la séance)
      try {
        final stats = await ActionJeuService.getStatsSeance(widget.seanceId);
        for (final ex in seance.exercices) {
          if (ex.id == null) continue;
          final key = ex.id.toString();
          final hasStats =
              stats.containsKey(key) && (stats[key] as Map).isNotEmpty;
          _exercicesTermines[ex.id!] = hasStats;
        }
      } catch (_) {
        // Non bloquant : si cet appel échoue, on considère juste tout "à faire"
      }

      setState(() {
        _planning = planning;
        _seance = seance;
        _loading = false;
      });

      AnalyticsService.trackEvent(
        'seance_execution_opened',
        data: {
          'planning_id': widget.planningId,
          'seance_id': widget.seanceId,
          'exercices_count': seance.exercices.length,
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

  Future<void> _ouvrirExercice(Exercice exercice) async {
    if (exercice.id == null)
      return; // sécurité : ne devrait jamais arriver en pratique

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActionSaisieForm(
          seanceId: widget.seanceId,
          exercice: exercice,
          joueurs: _planning!.joueurs,
          onTermine: () {
            setState(() => _exercicesTermines[exercice.id!] = true);
          },
        ),
      ),
    );

    if (result == true) {
      setState(() => _exercicesTermines[exercice.id!] = true);
    }
  }

  void _voirStats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatsSeanceScreen(
          planningId: widget.planningId,
          seanceId: widget.seanceId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(_seance?.titre ?? l10n.executerSeanceTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        actions: [
          if (_exercicesTermines.values.any((v) => v))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart_rounded, size: 18),
                label: Text(l10n.statsSeanceTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06D6A0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _voirStats,
              ),
            ),
        ],
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
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.red),
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
    final exercices = List<Exercice>.from(_seance?.exercices ?? [])
        .where((e) => e.id != null)
        .toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));

    if (exercices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.aucunExerciceMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray)),
        ),
      );
    }

    final nbTermines = _exercicesTermines.values.where((v) => v).length;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.red,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProgressHeader(nbTermines, exercices.length, l10n),
          const SizedBox(height: 16),
          ...exercices.asMap().entries.map((entry) {
            final index = entry.key;
            final exercice = entry.value;
            final termine = _exercicesTermines[exercice.id] ?? false;
            return _buildExerciceCard(exercice, index + 1, termine, l10n);
          }),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(
      int nbTermines, int total, AppLocalizations l10n) {
    final progress = total > 0 ? nbTermines / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.charcoal, Color(0xFF2d2d4e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.progressionLabel(nbTermines, total),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF06D6A0)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciceCard(
      Exercice exercice, int numero, bool termine, AppLocalizations l10n) {
    final localeCode = Localizations.localeOf(context).languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _ouvrirExercice(exercice),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: termine
                    ? const Color(0xFF06D6A0).withOpacity(0.3)
                    : AppColors.grayLight,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Badge numéro / statut
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: termine
                        ? const Color(0xFF06D6A0)
                        : AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: termine
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 22)
                      : Text('$numero',
                          style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercice.nom,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...exercice.domaines.map((d) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppConstants.domaineColor(d)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ActionJeuLabels.domaineLabel(d, localeCode),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppConstants.domaineColor(d)),
                                ),
                              )),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.grayXLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${exercice.duree} min',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gray)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  termine
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: termine ? const Color(0xFF06D6A0) : AppColors.gray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
