import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// Affiche la bottom sheet IA et retourne le planning généré.
///
/// Retourne [Map<String, dynamic>] si un planning a été généré, [null] sinon.
Future<Map<String, dynamic>?> showAiGeneratorDialog(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  useSafeArea: true,                    // ← ajoute ça
  builder: (ctx) => DraggableScrollableSheet(
    initialChildSize: 0.9,             // 90% de l'écran au départ
    minChildSize: 0.5,
    maxChildSize: 0.95,
    expand: false,
    builder: (_, scrollController) => const _AiGeneratorSheet(),
  ),
);
}

// ── Exemples de prompts ────────────────────────────────────────────
const _promptExamples = [
  "3 séances sur la réception et la défense, niveau intermédiaire",
  "2 séances intensives axées sur le service sautée et l'attaque",
  "Un programme de 4 séances pour travailler la cohésion et le bloc",
  "1 séance spécifique pour les libéros, focus réception en plongeon",
];

// ── Bottom Sheet ───────────────────────────────────────────────────
class _AiGeneratorSheet extends StatefulWidget {
  const _AiGeneratorSheet();

  @override
  State<_AiGeneratorSheet> createState() => _AiGeneratorSheetState();
}

class _AiGeneratorSheetState extends State<_AiGeneratorSheet>
    with TickerProviderStateMixin {
  final _promptCtrl = TextEditingController();
  bool _useStats = false;
  bool _loading = false;
  String? _errorMsg;

  // Animation du loader
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Animation d'entrée du sheet
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() => _errorMsg = "Décris ce que tu veux entraîner 😊");
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final localeCode = Localizations.localeOf(context).languageCode;
      final result = await AiService.generatePlanning(
        prompt: prompt,
        useStats: _useStats,
        language: localeCode,
      );
      if (mounted) Navigator.pop(context, result);
    } on ForbiddenException {
      setState(() {
        _loading = false;
        _errorMsg = AppLocalizations.of(context)!.aiDialogPremiumError;
      });
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = "Une erreur inattendue s'est produite. Réessaie.";
      });
    }
  }

  @override
Widget build(BuildContext context) {
  final bottomPad = MediaQuery.of(context).viewInsets.bottom;

  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(_slideAnim),
    child: Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C47FF).withOpacity(0.18),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      // ── Ici on remplace le Padding+Column par un SingleChildScrollView ──
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, max(24, bottomPad + 16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // En-tête avec gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C47FF), Color(0xFF3A86FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('✨', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.aiDialogTitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                          const Text(
                            'Powered by AI ',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('PREMIUM +',
                            style: TextStyle(
                                color: AppColors.charcoal,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.aiDialogSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Champ texte principal
            Text(AppLocalizations.of(context)!.aiDialogInputLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.charcoal)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptCtrl,
              enabled: !_loading,
              maxLines: 4,
              maxLength: 1000,
              onChanged: (_) {
                if (_errorMsg != null) setState(() => _errorMsg = null);
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.aiDialogInputHint,
                hintStyle: const TextStyle(
                    color: AppColors.gray, fontStyle: FontStyle.italic),
                filled: true,
                fillColor: AppColors.grayXLight,
                counterStyle:
                    const TextStyle(color: AppColors.gray, fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF6C47FF), width: 1.5),
                ),
                errorText: _errorMsg,
                errorStyle: const TextStyle(color: AppColors.red),
              ),
            ),

            const SizedBox(height: 16),

            // Toggle stats
            GestureDetector(
              onTap: _loading
                  ? null
                  : () => setState(() => _useStats = !_useStats),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _useStats
                      ? const Color(0xFF6C47FF).withOpacity(0.07)
                      : AppColors.grayXLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _useStats
                        ? const Color(0xFF6C47FF).withOpacity(0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color:
                          _useStats ? const Color(0xFF6C47FF) : AppColors.gray,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.aiDialogStatsLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _useStats
                                  ? const Color(0xFF6C47FF)
                                  : AppColors.charcoal,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.aiDialogStatsSubtitle,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.gray),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useStats,
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => _useStats = v),
                      activeColor: const Color(0xFF6C47FF),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton Générer
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _loading
                  ? _LoadingButton(
                      pulseAnim: _pulseAnim,
                      l10n: AppLocalizations.of(context)!,
                    )
                  : ElevatedButton(
                      onPressed: _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C47FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✨ ', style: TextStyle(fontSize: 16)),
                          Text(
                            AppLocalizations.of(context)!.aiDialogGenerateBtn,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 8),

            // Bouton annuler
            Center(
              child: TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context, null),
                child: Text(AppLocalizations.of(context)!.aiDialogCancelBtn,
                    style: const TextStyle(color: AppColors.gray)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

// ── Bouton de chargement animé ─────────────────────────────────────
class _LoadingButton extends StatelessWidget {
  final Animation<double> pulseAnim;
  final AppLocalizations l10n;

  const _LoadingButton({required this.pulseAnim, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final steps = [
      l10n.aiDialogLoading1,
      l10n.aiDialogLoading2,
      l10n.aiDialogLoading3,
      l10n.aiDialogLoading4,
    ];

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C47FF).withOpacity(0.7 + 0.3 * pulseAnim.value),
                const Color(0xFF3A86FF).withOpacity(0.7 + 0.3 * pulseAnim.value),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  steps[DateTime.now().second % steps.length],
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
