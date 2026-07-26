import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class TarifScreen extends StatefulWidget {
  const TarifScreen({super.key});

  @override
  State<TarifScreen> createState() => _TarifScreenState();
}

class _TarifScreenState extends State<TarifScreen> {
  // Le forfait actuellement en cours de paiement (null = aucun)
  String? _loadingForfait;
  String? _feedbackMessage;

  Future<void> _startPayment(String forfait, int montant) async {
    setState(() {
      _loadingForfait = forfait;
      _feedbackMessage = null;
    });

    try {
      final response = await ApiService.post('/kpay/initier', {
        'montant': montant,
        //'currency': 'XAF',
        'forfait': forfait, // BASIC | PREMIUM | PREMIUM_PLUS
      });

      final paymentUrl = response['gateway_url'] as String? ??
          response['gateway_url'] as String? ??
          response['data']?['gateway_url'] as String?;

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception(AppLocalizations.of(context)!.tarifPaymentUrlMissing);
      }

      final launched = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception(AppLocalizations.of(context)!.tarifPaymentOpenFailed);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tarifRedirecting),
          backgroundColor: const Color(0xFF06D6A0),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_feedbackMessage ??
              AppLocalizations.of(context)!.tarifPaymentFailed),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingForfait = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(l10n.tarifPageTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tarifHeadline,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tarifSubheadline,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.gray, height: 1.5),
              ),
              const SizedBox(height: 28),

              // ── Grille de forfaits ──────────────────────────────
              isMobile
                  ? Column(children: _buildCartes(l10n, isMobile))
                  : _buildGrilleDesktop(l10n),

              if (_feedbackMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.redLight),
                  ),
                  child: Text(
                    _feedbackMessage!,
                    style: const TextStyle(
                        color: AppColors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _buildNoteBasCarte(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrilleDesktop(AppLocalizations l10n) {
    final cartes = _buildCartes(l10n, false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cartes
          .asMap()
          .entries
          .map((e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: e.key == 0 ? 0 : 8,
                      right: e.key == cartes.length - 1 ? 0 : 8),
                  child: e.value,
                ),
              ))
          .toList(),
    );
  }

  List<Widget> _buildCartes(AppLocalizations l10n, bool isMobile) {
    return [
      _buildPlanCard(
        l10n: l10n,
        forfaitKey: null, // gratuit — pas de paiement
        title: l10n.tarifDecouverteTitle,
        price: '0',
        subtitle: l10n.tarifDecouverteSubtitle,
        accentColor: AppColors.gray,
        badge: null,
        featuresNouvelles: [
          l10n.featCreerModifierSupprimerPlanning,
          l10n.featGererJoueurs,
          l10n.featUnCollaborateur,
          l10n.featBilanParPlanning,
          l10n.featExportPdf,
        ],
        heriteDe: null,
        isMobile: isMobile,
      ),
      _buildPlanCard(
        l10n: l10n,
        forfaitKey: 'BASIC',
        title: l10n.tarifBasicTitle,
        price: '25 000',
        currency: 'XAF',
        subtitle: l10n.tarifBasicSubtitle,
        accentColor: const Color(0xFF3A86FF),
        badge: null,
        featuresNouvelles: [
          l10n.featBilanGlobal,
          l10n.featCollaborateursIllimites,
        ],
        heriteDe: l10n.tarifDecouverteTitle,
        isMobile: isMobile,
      ),
      _buildPlanCard(
        l10n: l10n,
        forfaitKey: 'PREMIUM',
        title: l10n.tarifPremiumTitle,
        price: '50 000',
        currency: 'XAF',
        subtitle: l10n.tarifPremiumSubtitle,
        accentColor: AppColors.red,
        badge: l10n.tarifBadgePopulaire,
        featuresNouvelles: [
          l10n.featExportExcel,
          l10n.featPartagePublic,
          l10n.featNoterPresences,
        ],
        heriteDe: l10n.tarifBasicTitle,
        isMobile: isMobile,
      ),
      _buildPlanCard(
        l10n: l10n,
        forfaitKey: 'PREMIUM_PLUS',
        title: l10n.tarifPremiumPlusTitle,
        price: '125 000',
        currency: 'XAF',
        subtitle: l10n.tarifPremiumPlusSubtitle,
        accentColor: const Color(0xFF8338EC),
        badge: l10n.tarifBadgeComplet,
        featuresNouvelles: [
          l10n.featGenerationIA,
          l10n.featExecuterSeance,
          l10n.featAnalyseAvancee,
        ],
        heriteDe: l10n.tarifPremiumTitle,
        isMobile: isMobile,
      ),
    ];
  }

  Widget _buildPlanCard({
    required AppLocalizations l10n,
    required String? forfaitKey,
    required String title,
    required String price,
    required String subtitle,
    required Color accentColor,
    required String? badge,
    required List<String> featuresNouvelles,
    required String? heriteDe,
    required bool isMobile,
    String currency = '',
  }) {
    final estPayant = forfaitKey != null;
    final enCoursDePaiement = _loadingForfait == forfaitKey;
    final unAutrePaiementEnCours =
        _loadingForfait != null && _loadingForfait != forfaitKey;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: estPayant
              ? accentColor.withOpacity(0.35)
              : AppColors.grayLight,
          width: badge != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: badge != null
                ? accentColor.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: badge != null ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête : nom + badge ──────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Prix ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal,
                ),
              ),
              if (currency.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$currency ${l10n.tarifParMois}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray,
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 6),
                  child: Text(
                    l10n.tarifGratuitPourToujours,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
                color: AppColors.gray, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),

          // ── Héritage cumulatif ("Tout Basic, plus :") ─────────
          if (heriteDe != null) ...[
            Row(
              children: [
                Icon(Icons.arrow_upward_rounded,
                    size: 14, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.tarifToutDePlus(heriteDe),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // ── Fonctionnalités nouvelles de ce palier ────────────
          ...featuresNouvelles.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feature,
                          style: const TextStyle(
                              color: AppColors.charcoal,
                              fontSize: 13.5,
                              height: 1.3)),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 6),

          // ── Bouton d'action ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: estPayant
                ? ElevatedButton(
                    onPressed: (enCoursDePaiement || unAutrePaiementEnCours)
                        ? null
                        : () => _startPayment(
                            forfaitKey, _montantPourForfait(forfaitKey)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      disabledBackgroundColor:
                          accentColor.withOpacity(0.4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: enCoursDePaiement
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.tarifChoisirCeForfait(title)),
                  )
                : OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.charcoal,
                      side: const BorderSide(color: AppColors.grayLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.tarifCommencerGratuitement),
                  ),
          ),
        ],
      ),
    );
  }

  int _montantPourForfait(String forfait) {
    switch (forfait) {
      case 'BASIC':
        return 25000;
      case 'PREMIUM':
        return 50000;
      case 'PREMIUM_PLUS':
        return 125000;
      default:
        return 0;
    }
  }

  Widget _buildNoteBasCarte(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grayXLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.gray),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.tarifNoteCumulative,
              style: const TextStyle(
                  color: AppColors.gray, fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}