import 'package:flutter/material.dart';
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
  bool _isLoading = false;
  String? _feedbackMessage;

  Future<void> _startPremiumPayment() async {
    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    try {
      final response = await ApiService.post('/cinetpay/initier', {
        'montant': 65000,
        'currency': 'XAF',
      });

      final paymentUrl = response['payment_url'] as String? ??
          response['paymentUrl'] as String? ??
          response['data']?['payment_url'] as String?;

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('Aucune URL de paiement n’a été retournée par l’API.');
      }

      final launched = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Impossible d’ouvrir la page de paiement.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirection vers le paiement Premium…'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_feedbackMessage ?? 'Échec de l’initiation du paiement.'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Forfaits & tarifs'),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez le forfait adapté à votre usage',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'VolleyPlan vous propose deux options simples : une version gratuite pour débuter, et un accès Premium pour débloquer toutes les fonctionnalités avancées.',
                style:
                    TextStyle(fontSize: 15, color: AppColors.gray, height: 1.5),
              ),
              const SizedBox(height: 24),
              _buildPlanCard(
                title: 'FREE',
                price: '0',
                subtitle: 'Parfait pour découvrir l’application',
                accentColor: AppColors.charcoal,
                features: [
                  'Gestion de base des séances',
                  'Création de plannings simples',
                  'Suivi des joueurs de base',
                ],
                isFeatured: false,
              ),
              const SizedBox(height: 16),
              _buildPlanCard(
                title: 'PREMIUM',
                price: '65 000',
                currency: 'XAF',
                subtitle: 'Accès complet pour les équipes professionnelles',
                accentColor: AppColors.red,
                features: [
                  'Toutes les fonctionnalités FREE',
                  'Statistiques avancées des joueurs',
                  'Accès aux analyses et rapports',
                  'Support prioritaire et mises à jour',
                ],
                isFeatured: true,
                actionLabel:
                    _isLoading ? 'Initialisation…' : 'Passer au Premium',
                onActionPressed: _isLoading ? null : _startPremiumPayment,
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String subtitle,
    required Color accentColor,
    required List<String> features,
    required bool isFeatured,
    String currency = '',
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isFeatured
                ? accentColor.withOpacity(0.3)
                : AppColors.grayLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (isFeatured) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded,
                    color: AppColors.yellow, size: 18),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal,
                ),
              ),
              if (currency.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
                color: AppColors.gray, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 14),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feature,
                          style: const TextStyle(
                              color: AppColors.charcoal, fontSize: 14)),
                    ),
                  ],
                ),
              )),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
