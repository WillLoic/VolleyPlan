import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
//import '../../models/planning.dart';
import '../../models/seance.dart';
import '../../models/exercice.dart';
import '../../utils/constants.dart';
import '../../widgets/vp_button.dart';
import '../../widgets/domaine_chip.dart';
import '../../services/planning_service.dart';

class PlanningFormScreen extends StatefulWidget {
  final int? planningId; // null = création, non-null = modification
  final String? token;

  const PlanningFormScreen({super.key, this.planningId, this.token});

  @override
  State<PlanningFormScreen> createState() => _PlanningFormScreenState();
}

class _PlanningFormScreenState extends State<PlanningFormScreen> {
  bool _isEdit = false;
  bool _isOwner = true;
  bool _loading = false;
  int _step = 0;

  // Step 1
  final _titreCtrl = TextEditingController();
  String _mode = 'groupe';
  String _duree = 'hebdomadaire';
  int _nbSeances = 3;
  List<String> _selectedPostes = [];
  String? _dateDebut;
  String? _dateFin;

  // Step 2
  List<int> _selectedJoueurIds = [];

  // Step 3
  List<Seance> _seances = [];
  int _currentSeance = 0;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.planningId != null;
    if (_isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final planning = await context
        .read<AppState>()
        .loadPlanning(widget.planningId!, token: widget.token);
    setState(() {
      _isOwner = widget.token == null &&
          planning.isOwner(context.read<AppState>().coach?.id);
      _titreCtrl.text = planning.titre;
      _mode = planning.mode;
      _duree = planning.duree;
      _nbSeances = planning.nbSeances;
      _selectedPostes =
          planning.poste?.split(', ').where((s) => s.isNotEmpty).toList() ?? [];
      _dateDebut = planning.dateDebut;
      _dateFin = planning.dateFin;
      _selectedJoueurIds = planning.joueurs.map((j) => j.id).toList();
      _seances = List.from(planning.seances);
      _loading = false;
    });
  }

  void _initSeances() {
    if (_seances.isEmpty) {
      _seances = List.generate(
          _nbSeances, (i) => Seance(titre: 'Séance ${i + 1}', ordre: i));
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final data = {
        'titre': _titreCtrl.text.trim(),
        'mode': _mode,
        'duree': _duree,
        'nb_seances': _nbSeances,
        'poste': _selectedPostes.isEmpty ? null : _selectedPostes.join(', '),
        'date_debut': _dateDebut,
        'date_fin': _dateFin,
        'joueur_ids': _selectedJoueurIds,
        'seances': _seances.map((s) => s.toJson()).toList(),
      };

      if (_isEdit) {
        await context.read<AppState>().updatePlanning(widget.planningId!, data);//, token: widget.token);
      } else {
        await context.read<AppState>().createPlanning(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modification réussie !')),
        );
        if (_isOwner) {
          context.go('/home');
        } else {
          context.go('/collaborations/${widget.token}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _validateSchedule(int index) async {
    final s = _seances[index];
    if (s.dateSeance == null || s.heureDebut == null) return;

    String? msg;
    // 1. Vérification locale (doublons dans le même formulaire)
    for (int i = 0; i < _seances.length; i++) {
      if (i == index) continue;
      if (_seances[i].dateSeance == s.dateSeance &&
          _seances[i].heureDebut?.trim() == s.heureDebut?.trim()) {
        msg =
            "La séance ${i + 1} est déjà prévue au même moment dans ce planning.";
        break;
      }
    }

    // 2. Vérification serveur si pas de doublon local
    if (msg == null) {
      final res = await PlanningService.checkOverlap({
        'date_seance': s.dateSeance,
        'heure_debut': s.heureDebut,
        'planning_id': widget.planningId,
      });
      if (res['overlap'] == true) {
        msg = res['message'];
      }
    }

    if (msg != null && mounted) {
      final bool proceed = await _showOverlapDialog(msg);
      if (!proceed) {
        setState(() {
          _seances[index] = Seance(
            id: s.id,
            planningId: s.planningId,
            titre: s.titre,
            ordre: s.ordre,
            domaines: s.domaines,
            dateSeance: null,
            heureDebut: null,
            lieu: s.lieu,
            notes: s.notes,
            exercices: s.exercices,
          );
        });
      }
    }
  }

  Future<bool> _showOverlapDialog(String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Conflit détecté',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ]),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler (Changer)',
                    style: TextStyle(color: AppColors.gray)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('OK (Confirmer)',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showAlert(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _isEdit) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.red)));
    }

    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Modifier le planning' : 'Nouveau planning',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          // Stepper header
          _StepHeader(current: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: [
                _Step1(
                  titreCtrl: _titreCtrl,
                  mode: _mode,
                  duree: _duree,
                  nbSeances: _nbSeances,
                  selectedPostes: _selectedPostes,
                  dateDebut: _dateDebut,
                  dateFin: _dateFin,
                  isOwner: _isOwner,
                  onModeChange: (v) => setState(() => _mode = v),
                  onDureeChange: (v) => setState(() => _duree = v),
                  onNbChange: (v) => setState(() => _nbSeances = v),
                  onPosteToggle: (p) => setState(() {
                    if (_selectedPostes.contains(p)) {
                      _selectedPostes.remove(p);
                    } else {
                      _selectedPostes.add(p);
                    }
                  }),
                  onDateDebutChange: (v) => setState(() => _dateDebut = v),
                  onDateFinChange: (v) => setState(() => _dateFin = v),
                ),
                _Step2(
                  selectedIds: _selectedJoueurIds,
                  onToggle: (id) => setState(() {
                    _selectedJoueurIds.contains(id)
                        ? _selectedJoueurIds.remove(id)
                        : _selectedJoueurIds.add(id);
                  }),
                  onSelectAll: (select) => setState(() {
                    if (select) {
                      _selectedJoueurIds =
                          state.joueurs.map((j) => j.id).toList();
                    } else {
                      _selectedJoueurIds = [];
                    }
                  }),
                ),
                _Step3(
                  seances: _seances,
                  currentSeance: _currentSeance,
                  onSeanceChange: (i) => setState(() => _currentSeance = i),
                  onSeancesUpdate: (s) => setState(() => _seances = s),
                  onScheduleChanged: () => _validateSchedule(_currentSeance),
                  limitStart: _dateDebut,
                  limitEnd: _dateFin,
                ),
              ][_step],
            ),
          ),
          // Navigation footer
          _NavFooter(
            step: _step,
            loading: _loading,
            isEdit: _isEdit,
            onBack: _step == 0 ? null : () => setState(() => _step--),
            onNext: _step < 2
                ? () {
                    if (_step == 1) _initSeances();
                    setState(() => _step++);
                  }
                : null,
            onSave: _step == 2 ? _save : null,
          ),
        ],
      ),
    );
  }
}

// ── Step Header ───────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final int current;
  const _StepHeader({required this.current});

  @override
  Widget build(BuildContext context) {
    final labels = ['Paramètres', 'Participants', 'Séances'];
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: labels.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(children: [
              if (i > 0)
                Expanded(
                    child: Divider(
                        color: done ? AppColors.red : AppColors.grayLight,
                        thickness: 2)),
              Column(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.red
                        : active
                            ? AppColors.red
                            : AppColors.grayLight,
                  ),
                  child: Center(
                      child: done
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      active ? Colors.white : AppColors.gray))),
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppColors.red
                            : done
                                ? AppColors.charcoal
                                : AppColors.gray)),
              ]),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Nav Footer ────────────────────────────────────────────────────
class _NavFooter extends StatelessWidget {
  final int step;
  final bool loading, isEdit;
  final VoidCallback? onBack, onNext, onSave;

  const _NavFooter(
      {required this.step,
      required this.loading,
      required this.isEdit,
      this.onBack,
      this.onNext,
      this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: AppColors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2))
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          onBack != null
              ? VpButton(
                  label: '← Retour',
                  onPressed: onBack,
                  variant: VpButtonVariant.ghost)
              : const SizedBox(),
          if (onNext != null) VpButton(label: 'Suivant →', onPressed: onNext),
          if (onSave != null)
            VpButton(
              label: isEdit ? '💾 Modifier' : '💾 Enregistrer',
              onPressed: onSave,
              loading: loading,
            ),
        ],
      ),
    );
  }
}

// ── Step 1 — Paramètres ───────────────────────────────────────────
class _Step1 extends StatelessWidget {
  final TextEditingController titreCtrl;
  final String mode, duree;
  final int nbSeances;
  final List<String> selectedPostes;
  final String? dateDebut, dateFin;
  final bool isOwner;
  final void Function(String) onModeChange, onDureeChange;
  final void Function(int) onNbChange;
  final void Function(String) onPosteToggle;
  final void Function(String?) onDateDebutChange, onDateFinChange;

  const _Step1({
    required this.titreCtrl,
    required this.mode,
    required this.duree,
    required this.nbSeances,
    required this.selectedPostes,
    this.dateDebut,
    this.dateFin,
    this.isOwner = true,
    required this.onModeChange,
    required this.onDureeChange,
    required this.onNbChange,
    required this.onPosteToggle,
    required this.onDateDebutChange,
    required this.onDateFinChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Paramètres généraux'),
        _card(Column(children: [
          _field('Titre du planning', titreCtrl, 'Ex: Prépa championnat 2025',
              enabled: isOwner),
          const SizedBox(height: 16),

          // Mode
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Mode',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal))),
          const SizedBox(height: 8),
          Row(children: [
            _modeBtn(
                'groupe', '👥 Groupe', mode, isOwner ? onModeChange : (_) {}),
            const SizedBox(width: 12),
            _modeBtn('individuel', '🎯 Spécifique', mode,
                isOwner ? onModeChange : (_) {}),
          ]),
          const SizedBox(height: 16),

          // Si individuel → poste
          if (mode == 'individuel') ...[
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Postes concernés',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.postes.map((p) {
                final isSelected = selectedPostes.contains(p);
                return FilterChip(
                  label: Text(p,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              isSelected ? Colors.white : AppColors.charcoal)),
                  selected: isSelected,
                  onSelected: (_) => onPosteToggle(p),
                  selectedColor: AppColors.red,
                  checkmarkColor: Colors.white,
                  backgroundColor: AppColors.grayXLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: isSelected
                              ? AppColors.red
                              : AppColors.grayLight)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Durée
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Durée',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: duree,
                    decoration: _inputDeco(),
                    items: const [
                      DropdownMenuItem(
                          value: 'hebdomadaire', child: Text('Hebdomadaire')),
                      DropdownMenuItem(
                          value: 'mensuel', child: Text('Mensuel')),
                      DropdownMenuItem(
                          value: 'trimestriel', child: Text('Trimestriel')),
                      DropdownMenuItem(
                          value: 'semestriel', child: Text('Semestriel')),
                      DropdownMenuItem(value: 'annuel', child: Text('Annuel')),
                    ],
                    onChanged: isOwner ? (v) => onDureeChange(v!) : null,
                  ),
                ])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Nombre de séances',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: '$nbSeances',
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco(),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) onNbChange(n);
                    },
                  ),
                ])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _datePickerField(context, 'Date de début', dateDebut,
                    isOwner ? (v) => onDateDebutChange(v) : null)),
            const SizedBox(width: 16),
            Expanded(
                child: _datePickerField(context, 'Date de fin', dateFin,
                    isOwner ? (v) => onDateFinChange(v) : null)),
          ]),
        ])),
      ],
    );
  }

  Widget _datePickerField(BuildContext context, String label, String? value,
      void Function(String?)? onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal)),
      const SizedBox(height: 8),
      InkWell(
        onTap: onSelect == null
            ? null
            : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      value != null ? DateTime.parse(value) : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null)
                  onSelect(DateFormat('yyyy-MM-dd').format(picked));
              },
        child: InputDecorator(
          decoration: _inputDeco(),
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.gray),
            const SizedBox(width: 8),
            Text(value ?? 'Choisir...', style: const TextStyle(fontSize: 13)),
          ]),
        ),
      ),
    ]);
  }

  Widget _modeBtn(String value, String label, String current,
      void Function(String) onChange) {
    final selected = current == value;
    return Expanded(
        child: GestureDetector(
      onTap: () => onChange(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.redLight : AppColors.white,
          border: Border.all(
              color: selected ? AppColors.red : AppColors.grayLight, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.red : AppColors.gray)),
      ),
    ));
  }
}

// ── Step 2 — Participants ─────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final List<int> selectedIds;
  final void Function(int) onToggle;
  final void Function(bool) onSelectAll;

  const _Step2(
      {required this.selectedIds,
      required this.onToggle,
      required this.onSelectAll});

  @override
  Widget build(BuildContext context) {
    final joueurs = context.watch<AppState>().joueurs;
    final allSelected =
        joueurs.isNotEmpty && selectedIds.length == joueurs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Participants (${selectedIds.length})'),
            if (joueurs.isNotEmpty)
              Row(
                children: [
                  const Text('Tout sélectionner',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray,
                          fontWeight: FontWeight.w600)),
                  Checkbox(
                    value: allSelected,
                    onChanged: (v) => onSelectAll(v ?? false),
                    activeColor: AppColors.red,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
          ],
        ),
        if (joueurs.isEmpty)
          _card(Column(children: [
            const Text('Aucun joueur dans votre roster.',
                style: TextStyle(color: AppColors.gray)),
            const SizedBox(height: 12),
            const Text('Ajoutez des joueurs depuis l\'onglet Joueurs.',
                style: TextStyle(color: AppColors.gray, fontSize: 12)),
          ]))
        else
          _card(Column(
            children: joueurs.map((j) {
              final selected = selectedIds.contains(j.id);
              return CheckboxListTile(
                value: selected,
                onChanged: (_) => onToggle(j.id),
                activeColor: AppColors.red,
                title: Text(j.nom,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: j.poste != null
                    ? Text(j.poste!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray))
                    : null,
                secondary: CircleAvatar(
                  backgroundColor: AppColors.redLight,
                  child: Text(j.nom[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.red, fontWeight: FontWeight.w800)),
                ),
              );
            }).toList(),
          )),
      ],
    );
  }
}

// ── Step 3 — Séances ──────────────────────────────────────────────
class _Step3 extends StatelessWidget {
  final List<Seance> seances;
  final int currentSeance;
  final void Function(int) onSeanceChange;
  final void Function(List<Seance>) onSeancesUpdate;
  final VoidCallback onScheduleChanged;
  final String? limitStart, limitEnd;

  const _Step3({
    required this.seances,
    required this.currentSeance,
    required this.onSeanceChange,
    required this.onSeancesUpdate,
    required this.onScheduleChanged,
    this.limitStart,
    this.limitEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (seances.isEmpty)
      return const Center(child: Text('Aucune séance configurée.'));
    final s = seances[currentSeance];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Onglets séances
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: seances.asMap().entries.map((e) {
              final i = e.key;
              final selected = i == currentSeance;
              return GestureDetector(
                onTap: () => onSeanceChange(i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.redLight : AppColors.white,
                    border: Border.all(
                        color: selected ? AppColors.red : AppColors.grayLight,
                        width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('S${i + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.red : AppColors.gray)),
                ),
              );
            }).toList(),
          ),
        ),

        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Titre séance
          _field('Titre', null, 'Séance ${currentSeance + 1}',
              initialValue: s.titre,
              key: ValueKey('titre_$currentSeance'), onChanged: (v) {
            seances[currentSeance] = _copySeance(s, titre: v);
            onSeancesUpdate(List.from(seances));
          }),
          const SizedBox(height: 14),

          // Date + heure
          Row(children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date (optionnel)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final start = limitStart != null
                        ? DateTime.parse(limitStart!)
                        : DateTime(2020);
                    final end = limitEnd != null
                        ? DateTime.parse(limitEnd!)
                        : DateTime(2100);

                    // On s'assure que la date initiale est bien dans les bornes
                    DateTime initial = s.dateSeance != null
                        ? (DateTime.tryParse(s.dateSeance!) ?? DateTime.now())
                        : (limitStart != null
                            ? DateTime.parse(limitStart!)
                            : DateTime.now());
                    if (initial.isBefore(start)) initial = start;
                    if (initial.isAfter(end)) initial = end;

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: start,
                      lastDate: end,
                    );
                    if (picked != null) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
                      seances[currentSeance] =
                          _copySeance(s, dateSeance: dateStr);
                      onSeancesUpdate(List.from(seances));
                      onScheduleChanged();
                    }
                  },
                  child: InputDecorator(
                    decoration: _inputDeco(),
                    child: Row(children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: AppColors.gray),
                      const SizedBox(width: 8),
                      Text(s.dateSeance ?? 'Choisir...',
                          style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                ),
              ],
            )),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heure (optionnel)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: s.heureDebut != null &&
                              s.heureDebut!.contains(':')
                          ? TimeOfDay(
                              hour: int.parse(s.heureDebut!.split(':')[0]),
                              minute: int.parse(s.heureDebut!.split(':')[1]))
                          : const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      final timeStr =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      seances[currentSeance] =
                          _copySeance(s, heureDebut: timeStr);
                      onSeancesUpdate(List.from(seances));
                      onScheduleChanged();
                    }
                  },
                  child: InputDecorator(
                    decoration: _inputDeco(),
                    child: Row(children: [
                      const Icon(Icons.access_time,
                          size: 16, color: AppColors.gray),
                      const SizedBox(width: 8),
                      Text(s.heureDebut ?? '00:00',
                          style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                ),
              ],
            )),
          ]),
          const SizedBox(height: 14),

          _field('Lieu (optionnel)', null, 'Gymnase, salle...',
              initialValue: s.lieu ?? '',
              key: ValueKey('lieu_$currentSeance'), onChanged: (v) {
            seances[currentSeance] = _copySeance(s, lieu: v);
            onSeancesUpdate(List.from(seances));
          }),
          const SizedBox(height: 14),

          // Domaines
          const Text('Domaines travaillés',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.domaines.map((d) {
                final id = d['id'] as String;
                return DomaineChip(
                  domaineId: id,
                  selected: s.domaines.contains(id),
                  onTap: () {
                    final doms = List<String>.from(s.domaines);
                    doms.contains(id) ? doms.remove(id) : doms.add(id);
                    seances[currentSeance] = _copySeance(s, domaines: doms);
                    onSeancesUpdate(List.from(seances));
                  },
                );
              }).toList()),
          const SizedBox(height: 16),

          // Exercices
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Exercices — ${AppConstants.fmtMinutes(s.dureeTotale)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal)),
            VpButton(
                label: '+ Exercice',
                small: true,
                onPressed: () {
                  final exs = List<Exercice>.from(s.exercices)
                    ..add(Exercice(
                        nom: '',
                        duree: 15,
                        domaine: s.domaines.isNotEmpty
                            ? s.domaines.first
                            : 'general',
                        ordre: s.exercices.length));
                  seances[currentSeance] = _copySeance(s, exercices: exs);
                  onSeancesUpdate(List.from(seances));
                }),
          ]),
          const SizedBox(height: 8),

          if (s.exercices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.grayXLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(
                  child: Text('Ajoutez vos exercices ici',
                      style: TextStyle(color: AppColors.gray))),
            ),

          ...s.exercices.asMap().entries.map((e) {
            final ei = e.key;
            final ex = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.grayXLight,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: TextFormField(
                    initialValue: ex.nom,
                    decoration: const InputDecoration(
                        hintText: 'Nom de l\'exercice',
                        border: InputBorder.none,
                        isDense: true),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    onChanged: (v) {
                      _updateEx(seances, currentSeance, ei, onSeancesUpdate,
                          nom: v);
                    },
                  )),
                  SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: '${ex.duree}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            suffix: Text('min'),
                            border: InputBorder.none,
                            isDense: true),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null)
                            _updateEx(
                                seances, currentSeance, ei, onSeancesUpdate,
                                duree: n);
                        },
                      )),
                  IconButton(
                    icon:
                        const Icon(Icons.close, size: 18, color: AppColors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final exs = List<Exercice>.from(s.exercices)
                        ..removeAt(ei);
                      seances[currentSeance] = _copySeance(s, exercices: exs);
                      onSeancesUpdate(List.from(seances));
                    },
                  ),
                ]),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: AppConstants.domaines.map((d) {
                    final id = d['id'] as String;
                    final selected = ex.domaine == id;
                    return GestureDetector(
                      onTap: () => _updateEx(
                          seances, currentSeance, ei, onSeancesUpdate,
                          domaine: id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: selected
                              ? (d['color'] as Color).withOpacity(0.15)
                              : Colors.white,
                          border: Border.all(
                              color: selected
                                  ? d['color'] as Color
                                  : AppColors.grayLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${d['icon']} ${d['label']}',
                            style: TextStyle(
                                fontSize: 10,
                                color: selected
                                    ? d['color'] as Color
                                    : AppColors.gray,
                                fontWeight: FontWeight.w700)),
                      ),
                    );
                  }).toList()),
                ),
              ]),
            );
          }),
        ])),
      ],
    );
  }

  Seance _copySeance(Seance s,
      {String? titre,
      List<String>? domaines,
      String? dateSeance,
      String? heureDebut,
      String? lieu,
      String? notes,
      List<Exercice>? exercices}) {
    return Seance(
      id: s.id,
      planningId: s.planningId,
      titre: titre ?? s.titre,
      ordre: s.ordre,
      domaines: domaines ?? s.domaines,
      dateSeance: dateSeance ?? s.dateSeance,
      heureDebut: heureDebut ?? s.heureDebut,
      lieu: lieu ?? s.lieu,
      notes: notes ?? s.notes,
      exercices: exercices ?? s.exercices,
    );
  }

  void _updateEx(
      List<Seance> seances, int si, int ei, void Function(List<Seance>) update,
      {String? nom, int? duree, String? domaine}) {
    final s = seances[si];
    final exs = List<Exercice>.from(s.exercices);
    final ex = exs[ei];
    exs[ei] = Exercice(
      id: ex.id,
      seanceId: ex.seanceId,
      nom: nom ?? ex.nom,
      duree: duree ?? ex.duree,
      domaine: domaine ?? ex.domaine,
      description: ex.description,
      ordre: ex.ordre,
    );
    seances[si] = _copySeance(s, exercices: exs);
    update(List.from(seances));
  }

  Seance _copySeance2(Seance s, {List<Exercice>? exercices}) => Seance(
        id: s.id,
        planningId: s.planningId,
        titre: s.titre,
        ordre: s.ordre,
        domaines: s.domaines,
        dateSeance: s.dateSeance,
        heureDebut: s.heureDebut,
        lieu: s.lieu,
        notes: s.notes,
        exercices: exercices ?? s.exercices,
      );
}

// ── Helpers partagés ──────────────────────────────────────────────
Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.charcoal)),
    );

Widget _card(Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: child,
    );

Widget _field(String label, TextEditingController? ctrl, String hint,
    {void Function(String)? onChanged,
    String? initialValue,
    Key? key,
    bool enabled = true}) {
  return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          readOnly: !enabled,
          initialValue: ctrl == null ? initialValue : null,
          decoration: _inputDeco(hint: hint),
          onChanged: onChanged,
        ),
      ]);
}

InputDecoration _inputDeco({String? hint}) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.grayXLight,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
