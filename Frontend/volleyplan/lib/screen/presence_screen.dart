import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/vp_button.dart';

class PresenceScreen extends StatefulWidget {
  final int seanceId;

  const PresenceScreen({super.key, required this.seanceId});

  @override
  State<PresenceScreen> createState() => _PresenceScreenState();
}

class _PresenceScreenState extends State<PresenceScreen> {
  bool _loading = true;
  String? _error;
  
  Map<String, dynamic>? _seance;
  bool _presencesPrises = false;
  bool _presencesAuto = false;
  bool _fenetreOuverte = false;
  
  List<Map<String, dynamic>> _playersState = [];

  @override
  void initState() {
    super.initState();
    _loadPresences();
  }

  Future<void> _loadPresences() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.get('/joueurs/seance/${widget.seanceId}/presences');
      
      if (res['success'] == true) {
        _seance = res['seance'];
        _presencesPrises = res['presences_prises'] ?? false;
        _presencesAuto = res['presences_auto'] ?? false;
        _fenetreOuverte = res['fenetre_ouverte'] ?? false;
        
        final list = res['joueurs'] as List;
        _playersState = list.map((item) {
          final j = item['joueur'];
          final present = item['present'] as bool;
          return {
            'id': j['id'],
            'nom': j['nom'],
            'poste': j['poste'],
            'absent': !present,
            'motif': item['motif'] ?? '',
            'controller': TextEditingController(text: item['motif'] ?? ''),
          };
        }).toList();
      } else {
        _error = res['message'] ?? 'Erreur inconnue';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePresences() async {
    setState(() => _loading = true);

    try {
      final absences = _playersState
          .where((p) => p['absent'] == true)
          .map((p) => {
                'joueur_id': p['id'],
                'motif': (p['controller'] as TextEditingController).text.trim(),
              })
          .toList();

      final res = await ApiService.post('/joueurs/seance/${widget.seanceId}/absences', {
        'absences': absences,
      });

      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.saveButton + ' OK'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        setState(() {
          _error = res['message'] ?? 'Erreur lors de l\'enregistrement';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var p in _playersState) {
      (p['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageAttendance),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
      ),
      backgroundColor: AppColors.offWhite,
      body: _loading && _seance == null
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
              onPressed: _loadPresences,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
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

    return Column(
      children: [
        // En-tête de la séance
        Container(
          width: double.infinity,
          color: AppColors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _seance?['titre'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              if (_seance?['date_seance'] != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.gray),
                    const SizedBox(width: 6),
                    Text(
                      _seance!['date_seance'] + (_seance!['heure_debut'] != null ? ' ' + l10n.atTime(_seance!['heure_debut']) : ''),
                      style: const TextStyle(color: AppColors.gray, fontSize: 13),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              
              // État actuel des présences
              _buildStatusBanner(l10n),
            ],
          ),
        ),
        
        // Liste des joueurs
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _playersState.length,
            itemBuilder: (context, index) {
              final p = _playersState[index];
              final isAbsent = p['absent'] as bool;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: isAbsent ? AppColors.redLight.withOpacity(0.4) : AppColors.white,
                elevation: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isAbsent ? AppColors.redLight : AppColors.grayXLight,
                            child: Text(
                              p['nom'][0].toUpperCase(),
                              style: TextStyle(
                                color: isAbsent ? AppColors.red : AppColors.charcoal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['nom'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                                if (p['poste'] != null)
                                  Text(
                                    getPosteLabel(p['poste']),
                                    style: const TextStyle(color: AppColors.gray, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Checkbox absent
                          Row(
                            children: [
                              Text(
                                l10n.markAbsent,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAbsent ? AppColors.red : AppColors.gray,
                                  fontWeight: isAbsent ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Checkbox(
                                value: isAbsent,
                                activeColor: AppColors.red,
                                onChanged: (val) {
  setState(() {
    p['absent'] = val ?? false;
  });
},
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Motif de l'absence
                      if (isAbsent) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: p['controller'] as TextEditingController,
                          //enabled: _fenetreOuverte,
                          decoration: InputDecoration(
                            hintText: l10n.motifAbsence,
                            filled: true,
                            fillColor: AppColors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.grayLight),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bouton de validation
        //if (_fenetreOuverte)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: SafeArea(
              child: VpButton(
                label: l10n.saveButton,
                onPressed: _loading ? null : _savePresences,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBanner(AppLocalizations l10n) {
    if (!_fenetreOuverte) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.yellowLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_clock, color: AppColors.yellow, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.presenceFenetreFermee,
                style: const TextStyle(color: AppColors.charcoal, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    String message = l10n.presenceNonSaisieMessage;
    Color color = AppColors.grayXLight;
    IconData icon = Icons.info_outline;
    Color iconColor = AppColors.gray;

    if (_presencesPrises) {
      if (_presencesAuto) {
        message = l10n.presenceAutoMessage;
        color = AppColors.yellowLight;
        icon = Icons.bolt;
        iconColor = AppColors.yellow;
      } else {
        message = l10n.presenceManuelleMessage;
        color = const Color(0xFFE8F5E9); // Vert clair
        icon = Icons.check_circle;
        iconColor = Colors.green;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.charcoal, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
