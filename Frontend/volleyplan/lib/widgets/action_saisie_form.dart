// lib/widgets/action_saisie_form.dart
//
// Écran plein format (poussé via Navigator.push) permettant de saisir
// rapidement les actions de jeu d'un exercice, joueur par joueur.
//
// UX pensée pour la vitesse terrain :
// - Sélection joueur = grille de chips (pas de dropdown)
// - Sélection des champs = chips à choix unique (pas de dropdown)
// - Le dernier joueur sélectionné reste actif (actions en rafale)
// - Bouton "Valider l'action" énorme, fixe en bas (zone du pouce)
// - Bouton "Terminer l'exercice" isolé dans l'AppBar (évite les taps accidentels)
// - Blocage total si l'envoi échoue — aucune perte de données

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/joueur.dart';
import '../models/exercice.dart';
import '../services/action_jeu_service.dart';
import '../utils/constants.dart';
import '../utils/domaines_action_config.dart';
//import '../utils/domaines_action_config.dart';
import '../utils/action_jeu_label.dart';

class ActionSaisieForm extends StatefulWidget {
  final int seanceId;
  final Exercice exercice;
  final List<Joueur> joueurs;
  final VoidCallback onTermine;

  const ActionSaisieForm({
    super.key,
    required this.seanceId,
    required this.exercice,
    required this.joueurs,
    required this.onTermine,
  });

  @override
  State<ActionSaisieForm> createState() => _ActionSaisieFormState();
}

class _ActionSaisieFormState extends State<ActionSaisieForm> {
  final List<Map<String, dynamic>> _actionsEnAttente = [];

  late List<String> _domaines;
  late String _domaineActif;

  int? _selectedJoueurId;
  final Map<String, String?> _selectedFields = {};
  
  // Map : { joueurId: { domaineActif: { champ: valeurVerrouillee } } }
  final Map<int, Map<String, Map<String, String>>> _lockedFields = {};

  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _domaines = ordreDomainesAction
        .where((d) => widget.exercice.domaines.contains(d))
        .toList();
    if (_domaines.isEmpty) _domaines = widget.exercice.domaines;
    _domaineActif = _domaines.first;
    _resetFields();
  }

  void _resetFields() {
    _selectedFields.clear();
    final config = domainesActionConfig[_domaineActif];
    if (config != null) {
      for (final champ in config.champs.keys) {
        if (_selectedJoueurId != null &&
            _lockedFields[_selectedJoueurId] != null &&
            _lockedFields[_selectedJoueurId]![_domaineActif] != null &&
            _lockedFields[_selectedJoueurId]![_domaineActif]!.containsKey(champ)) {
          _selectedFields[champ] = _lockedFields[_selectedJoueurId]![_domaineActif]![champ];
        } else {
          _selectedFields[champ] = null;
        }
      }
    }
  }

  void _changerDomaine(String domaine) {
    setState(() {
      _domaineActif = domaine;
      _resetFields();
    });
  }

  bool get _actionComplete {
    if (_selectedJoueurId == null) return false;
    return _selectedFields.values.every((v) => v != null);
  }

  void _validerAction() {
    if (!_actionComplete) return;

    final donnees = <String, dynamic>{};
    _selectedFields.forEach((champ, valeur) {
      donnees[champ] = valeur;
    });

    setState(() {
      _actionsEnAttente.add({
        'joueur_id': _selectedJoueurId,
        'domaine': _domaineActif,
        'donnees': donnees,
      });
      // Le joueur reste sélectionné (actions en rafale), les champs se réinitialisent
      _resetFields();
    });

    // Petit retour visuel/haptique léger pourrait être ajouté ici (HapticFeedback.lightImpact())
  }

  Future<void> _confirmerTerminer() async {
    final l10n = AppLocalizations.of(context)!;

    if (_actionsEnAttente.isEmpty) {
      widget.onTermine();
      Navigator.pop(context, true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.terminerExerciceTitle),
        content: Text(l10n.terminerExerciceConfirm(_actionsEnAttente.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.envoyerButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _envoyerBatch();
    }
  }

  Future<void> _envoyerBatch() async {
    setState(() {
      _sending = true;
      _sendError = null;
    });

    try {
      final res = await ActionJeuService.enregistrerBatch(
        widget.seanceId,
        widget.exercice.id!,
        _actionsEnAttente,
      );

      if (res['success'] == true) {
        widget.onTermine();
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _sendError = res['error'] ?? res['message'] ?? 'Erreur inconnue';
          _sending = false;
        });
      }
    } catch (e) {
      setState(() {
        _sendError = e.toString().replaceAll('Exception: ', '');
        _sending = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_actionsEnAttente.isEmpty) return true;
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quitterSansEnvoyerTitle),
        content: Text(l10n.quitterSansEnvoyerMessage(_actionsEnAttente.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.quitterButton),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          foregroundColor: AppColors.charcoal,
          title: Text(widget.exercice.nom,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          actions: [
            if (_actionsEnAttente.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text('${_actionsEnAttente.length}',
                    style: const TextStyle(
                        color: AppColors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(l10n.terminerExerciceTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _sending ? null : _confirmerTerminer,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_domaines.length > 1) _buildDomaineTabs(),
                if (_sendError != null) _buildErrorBanner(l10n),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildJoueurSelector(l10n),
                        const SizedBox(height: 20),
                        ..._buildChampsSelectors(localeCode),
                      ],
                    ),
                  ),
                ),
                _buildValiderBar(l10n),
              ],
            ),
            if (_sending) _buildSendingOverlay(l10n),
          ],
        ),
      ),
    );
  }

  // ── Tabs de domaine (si exercice multi-domaine) ──────────────────
  Widget _buildDomaineTabs() {
    final localeCode = Localizations.localeOf(context).languageCode;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: _domaines.map((d) {
          final active = d == _domaineActif;
          final color = AppConstants.domaineColor(d);
          return Expanded(
            child: GestureDetector(
              onTap: () => _changerDomaine(d),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? color : color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  ActionJeuLabels.domaineLabel(d, localeCode),
                  style: TextStyle(
                    color: active ? Colors.white : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      color: AppColors.red.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_sendError!,
                style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: _envoyerBatch,
            child: Text(l10n.reessayerButton,
                style: const TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ── Sélecteur de joueur ────────────────────────────────────────
  Widget _buildJoueurSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.joueurLabel,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.gray,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.joueurs.map((j) {
            final selected = j.id == _selectedJoueurId;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedJoueurId = j.id;
                _resetFields();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.red : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: selected ? AppColors.red : AppColors.grayLight,
                      width: 1.5),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: AppColors.red.withOpacity(0.25),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          selected ? Colors.white : AppColors.redLight,
                      child: Text(
                        j.nom.isNotEmpty ? j.nom[0].toUpperCase() : '?',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: selected ? AppColors.red : AppColors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(j.nom,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color:
                                selected ? Colors.white : AppColors.charcoal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Sélecteurs de champs du domaine actif ────────────────────────
  List<Widget> _buildChampsSelectors(String localeCode) {
    final config = domainesActionConfig[_domaineActif];
    if (config == null) return [];

    return config.champs.entries.map((entry) {
      final champ = entry.key;
      final valeurs = entry.value;
      final selectedValue = _selectedFields[champ];

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  ActionJeuLabels.champLabel(champ, localeCode, domaine: _domaineActif).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray,
                      letterSpacing: 0.5),
                ),
                const SizedBox(width: 8),
                if (_selectedJoueurId != null)
                  GestureDetector(
                    onTap: () {
                      final currentLock = _lockedFields[_selectedJoueurId!]?[_domaineActif]?[champ];
                      if (currentLock != null) {
                        // Déverrouiller
                        setState(() {
                          _lockedFields[_selectedJoueurId!]![_domaineActif]!.remove(champ);
                        });
                      } else if (selectedValue != null) {
                        // Verrouiller la valeur actuellement sélectionnée
                        setState(() {
                          _lockedFields.putIfAbsent(_selectedJoueurId!, () => {});
                          _lockedFields[_selectedJoueurId!]!.putIfAbsent(_domaineActif, () => {});
                          _lockedFields[_selectedJoueurId!]![_domaineActif]![champ] = selectedValue;
                        });
                      }
                    },
                    child: Icon(
                      _lockedFields[_selectedJoueurId!]?[_domaineActif]?.containsKey(champ) == true
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      size: 16,
                      color: _lockedFields[_selectedJoueurId!]?[_domaineActif]?.containsKey(champ) == true
                          ? AppColors.red
                          : (selectedValue != null ? AppColors.gray : AppColors.grayLight),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: valeurs.map((v) {
                final selected = v == selectedValue;
                final color = AppConstants.domaineColor(_domaineActif);
                return GestureDetector(
                  onTap: () => setState(() => _selectedFields[champ] = v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? color : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected ? color : AppColors.grayLight,
                          width: 1.5),
                    ),
                    child: Text(
                      ActionJeuLabels.valeurLabel(v, localeCode),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? Colors.white : AppColors.charcoal),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ── Barre fixe du bas — le geste le plus répété de l'écran ──────
  Widget _buildValiderBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_actionsEnAttente.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.actionsEnregistrees(_actionsEnAttente.length),
                  style: const TextStyle(
                      color: AppColors.gray,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _actionComplete ? _validerAction : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06D6A0),
                  disabledBackgroundColor: AppColors.grayLight,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 24),
                    const SizedBox(width: 8),
                    Text(l10n.validerActionButton,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendingOverlay(AppLocalizations l10n) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.red),
                const SizedBox(height: 16),
                Text(l10n.envoiEnCours,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
