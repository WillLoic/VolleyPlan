import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _buildHeader(context, isMobile),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 40,
                      vertical: 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(isMobile),
                        const SizedBox(height: 40),
                        _buildSection('1', 'Objet et acceptation',
                            AppColors.red, _objet),
                        _buildSection('2', 'Description du service',
                            AppColors.yellow, null,
                            customWidget: _buildServiceDescription(isMobile)),
                        _buildSection('3', 'Inscription et compte utilisateur',
                            const Color(0xFF3A86FF), null,
                            customWidget: _buildInscription(isMobile)),
                        _buildSection('4', 'Utilisation autorisée',
                            const Color(0xFF06D6A0), null,
                            customWidget: _buildAllowed(isMobile)),
                        _buildSection('5', 'Utilisations interdites',
                            AppColors.red, null,
                            customWidget: _buildForbidden(isMobile)),
                        _buildSection('6', 'Propriété des données',
                            const Color(0xFF8338EC), _dataOwnership),
                        _buildSection('7', 'Propriété intellectuelle',
                            AppColors.yellow, _ipSection),
                        _buildSection('8', 'Disponibilité du service',
                            const Color(0xFF3A86FF), _availability),
                        _buildSection('9', 'Responsabilités',
                            const Color(0xFF06D6A0), _responsibilities),
                        _buildSection('10', 'Évolution du service et des CGU',
                            AppColors.red, null,
                            customWidget: _buildEvolution(isMobile)),
                        _buildSection('11', 'Droit applicable',
                            AppColors.yellow, _law),
                        _buildContactSection(isMobile),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
            bottom: BorderSide(color: AppColors.grayLight, width: 1)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.go('/'),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.red, AppColors.yellow]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: Text('🏐', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
            const Text('VolleyPlan',
                style: TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 16, color: AppColors.charcoal)),
          ]),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded,
              size: 16, color: AppColors.gray),
          label: const Text('Retour',
              style: TextStyle(color: AppColors.gray,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2d2d4e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('DOCUMENT LÉGAL',
                style: TextStyle(color: AppColors.yellow,
                    fontSize: 11, fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 16),
          Text(
            '📋 Conditions Générales\nd\'Utilisation',
            style: TextStyle(
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                height: 1.2),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dernière mise à jour : juin 2026 · Version 1.0',
            style: TextStyle(color: AppColors.gray, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'En utilisant VolleyPlan, vous acceptez les présentes conditions. '
            'Prenez le temps de les lire — elles définissent nos droits et '
            'obligations mutuels.',
            style: TextStyle(color: AppColors.gray, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Section générique ────────────────────────────────────────────
  Widget _buildSection(
    String number,
    String title,
    Color color,
    String? content, {
    Widget? customWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Text(number,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.charcoal)),
              ),
            ]),
            const SizedBox(height: 16),
            if (content != null)
              Text(content,
                  style: const TextStyle(
                      color: AppColors.gray, fontSize: 14, height: 1.7)),
            if (customWidget != null) customWidget,
          ],
        ),
      ),
    );
  }

  // ── Service description ──────────────────────────────────────────
  Widget _buildServiceDescription(bool isMobile) {
    final features = [
      '📅 Création et gestion de plannings d\'entraînement',
      '👥 Gestion d\'un roster de joueurs par poste',
      '📊 Génération de bilans automatiques par domaine de jeu',
      '📄 Export de plannings au format PDF',
      '🤝 Collaboration entre membres du staff sportif',
      '💬 Partage de plannings via WhatsApp',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.substring(0, 2),
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f.substring(2).trim(),
                        style: const TextStyle(
                            color: AppColors.gray,
                            fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.yellow.withOpacity(0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🚧', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phase Beta',
                        style: TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 14, color: AppColors.charcoal)),
                    SizedBox(height: 4),
                    Text(
                      'Le service est gratuit pendant la beta. Des bugs peuvent survenir. '
                      'Des fonctionnalités peuvent évoluer. Aucune garantie de '
                      'disponibilité continue n\'est offerte.',
                      style: TextStyle(color: AppColors.gray,
                          fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Inscription ──────────────────────────────────────────────────
  Widget _buildInscription(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSection('Conditions d\'inscription', [
          'Être âgé d\'au moins 16 ans',
          'Fournir des informations exactes (nom, téléphone, équipe)',
          'Créer un mot de passe que vous gardez confidentiel',
        ], AppColors.red),
        const SizedBox(height: 12),
        _buildSubSection('Votre responsabilité', [
          'Confidentialité de votre mot de passe',
          'Toutes les activités effectuées depuis votre compte',
          'Exactitude des informations saisies',
        ], const Color(0xFF3A86FF)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A86FF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ℹ️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Un compte = un coach = une équipe. '
                  'La création de comptes multiples est interdite.',
                  style: TextStyle(color: AppColors.charcoal,
                      fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Allowed ──────────────────────────────────────────────────────
  Widget _buildAllowed(bool isMobile) {
    final items = [
      'Planifier vos séances d\'entraînement de volleyball',
      'Gérer le roster de votre équipe',
      'Analyser la répartition de votre volume d\'entraînement',
      'Partager vos plannings avec vos joueurs et staff',
      'Collaborer avec vos assistants coachs',
      'Utiliser VolleyPlan pour votre entraînement personnel (joueurs)',
    ];
    return Column(
      children: items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF06D6A0).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF06D6A0).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF06D6A0), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item,
                    style: const TextStyle(
                        color: AppColors.charcoal, fontSize: 13)),
              ),
            ]),
          )).toList(),
    );
  }

  // ── Forbidden ────────────────────────────────────────────────────
  Widget _buildForbidden(bool isMobile) {
    final categories = [
      {
        'title': 'Activités illégales',
        'items': [
          'Actes contraires à la législation camerounaise ou internationale',
          'Usurpation d\'identité ou faux profils',
          'Fraude envers d\'autres utilisateurs',
        ],
        'color': AppColors.red,
      },
      {
        'title': 'Atteintes techniques',
        'items': [
          'Pirater ou contourner les mesures de sécurité',
          'Attaques par déni de service',
          'Injection de code malveillant',
          'Accéder aux données d\'autres utilisateurs sans autorisation',
        ],
        'color': const Color(0xFF8338EC),
      },
      {
        'title': 'Abus du service',
        'items': [
          'Créer des contenus injurieux ou illicites',
          'Spammer d\'autres utilisateurs',
          'Utiliser des robots ou scripts automatisés',
          'Revendre l\'accès sans autorisation',
        ],
        'color': AppColors.yellow,
      },
    ];

    return Column(
      children: categories.map((cat) {
        final color = cat['color'] as Color;
        final items = cat['items'] as List<String>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.block_rounded, size: 16),
                const SizedBox(width: 8),
                Text(cat['title'] as String,
                    style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 13, color: color)),
              ]),
              const SizedBox(height: 10),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5, height: 5,
                          margin: const EdgeInsets.only(top: 7, right: 8),
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  color: AppColors.gray,
                                  fontSize: 13, height: 1.5)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Evolution ────────────────────────────────────────────────────
  Widget _buildEvolution(bool isMobile) {
    return Column(
      children: [
        _buildEvolutionCard(
          '🆓',
          'Phase Beta gratuite',
          'L\'accès gratuit actuel est lié à la phase Beta. Lors du passage '
          'à un modèle payant, vous serez prévenu au moins 30 jours à l\'avance.',
          AppColors.red,
        ),
        const SizedBox(height: 10),
        _buildEvolutionCard(
          '📤',
          'Export de vos données',
          'Avant toute décision de paiement, vous pourrez exporter tous vos '
          'plannings en PDF. Des fonctionnalités de base resteront gratuites.',
          AppColors.yellow,
        ),
        const SizedBox(height: 10),
        _buildEvolutionCard(
          '📢',
          'Modifications des CGU',
          'Nous pouvons modifier ces CGU. Toute modification importante sera '
          'notifiée via l\'application ou Facebook. L\'utilisation continue '
          'vaut acceptation.',
          const Color(0xFF3A86FF),
        ),
      ],
    );
  }

  Widget _buildEvolutionCard(
      String icon, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 14, color: color)),
          const SizedBox(height: 6),
          Text(desc,
              style: const TextStyle(color: AppColors.gray,
                  fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }

  // ── SubSection helper ─────────────────────────────────────────────
  Widget _buildSubSection(
      String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 13, color: color)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5, height: 5,
                    margin: const EdgeInsets.only(top: 7, right: 8),
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            color: AppColors.gray,
                            fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── Contact ──────────────────────────────────────────────────────
  Widget _buildContactSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.charcoal, Color(0xFF2d2d4e)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📬 Nous contacter',
            style: TextStyle(fontWeight: FontWeight.w800,
                fontSize: 18, color: AppColors.white)),
        const SizedBox(height: 12),
        const Text('Pour toute question relative aux présentes CGU :',
            style: TextStyle(color: AppColors.gray, fontSize: 14)),
        const SizedBox(height: 16),
        _contactRow('📘', 'Facebook', 'Page VolleyPlan'),
        _contactRow('💬', 'WhatsApp', 'Via la page Facebook'),
        _contactRow('⚖️', 'Juridiction', 'Tribunaux de Yaoundé, Cameroun'),
        _contactRow('🌍', 'Droit applicable', 'Droit camerounais'),
      ]),
    );
  }

  Widget _contactRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text('$label : ',
            style: const TextStyle(color: AppColors.gray,
                fontSize: 13, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.white, fontSize: 13)),
        ),
      ]),
    );
  }

  // ── Textes statiques ─────────────────────────────────────────────
  static const _objet =
      'Les présentes Conditions Générales d\'Utilisation (CGU) régissent '
      'l\'accès et l\'utilisation de l\'application VolleyPlan.\n\n'
      'En créant un compte ou en utilisant VolleyPlan, vous acceptez sans '
      'réserve les présentes CGU. Si vous n\'acceptez pas ces conditions, '
      'vous ne devez pas utiliser l\'application.';

  static const _dataOwnership =
      'Les plannings, joueurs et données que vous créez dans VolleyPlan '
      'vous appartiennent entièrement. Nous ne revendiquons aucun droit de '
      'propriété sur vos contenus.\n\n'
      'En utilisant VolleyPlan, vous nous accordez une licence limitée, '
      'non exclusive et non transférable pour héberger et traiter vos '
      'données dans le seul but de vous fournir le service.\n\n'
      'Vous êtes responsable d\'avoir obtenu les autorisations nécessaires '
      'pour saisir les données de vos joueurs.';

  static const _ipSection =
      'L\'application VolleyPlan, son code source, son design, ses algorithmes '
      'de calcul de bilan, son logo et ses textes sont protégés par le droit '
      'de la propriété intellectuelle.\n\n'
      'Il est interdit de copier ou reproduire l\'application, de créer une '
      'application dérivée, ou de décompiler le code source.';

  static const _availability =
      'Nous faisons nos meilleurs efforts pour maintenir VolleyPlan disponible. '
      'Cependant, pendant la phase Beta, nous ne garantissons pas une '
      'disponibilité 24h/24, l\'absence de bugs, ni la conservation permanente '
      'des données.\n\n'
      'Le service dépend de prestataires tiers (Render, Supabase, Firebase, '
      'Cloudflare). Des interruptions indépendantes de notre volonté peuvent '
      'survenir.';

  static const _responsibilities =
      'Dans les limites autorisées par la loi, VolleyPlan ne saurait être '
      'tenu responsable de perte de données due à une défaillance technique, '
      'd\'interruption de service imprévue, ou de décisions sportives prises '
      'sur la base des recommandations de l\'application.\n\n'
      'Vous êtes responsable de l\'utilisation que vous faites de l\'application '
      'et de la précision des données que vous saisissez. Nous recommandons '
      'd\'exporter régulièrement vos plannings en PDF.';

  static const _law =
      'Les présentes CGU sont régies par le droit camerounais.\n\n'
      'En cas de litige, nous privilégions la résolution amiable. '
      'À défaut, les tribunaux compétents de Yaoundé (Cameroun) '
      'sont seuls compétents.';
}