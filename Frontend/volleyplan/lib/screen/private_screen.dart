import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                        _buildSection(
                          number: '1',
                          title: 'Introduction',
                          color: AppColors.red,
                          content: _intro,
                        ),
                        _buildSection(
                          number: '2',
                          title: 'Qui sommes-nous ?',
                          color: AppColors.yellow,
                          content: _whoWeAre,
                        ),
                        _buildSection(
                          number: '3',
                          title: 'Données que nous collectons',
                          color: const Color(0xFF3A86FF),
                          content: null,
                          customWidget: _buildDataCollected(isMobile),
                        ),
                        _buildSection(
                          number: '4',
                          title: 'Pourquoi nous collectons ces données',
                          color: const Color(0xFF06D6A0),
                          content: null,
                          customWidget: _buildWhyTable(isMobile),
                        ),
                        _buildSection(
                          number: '5',
                          title: 'Comment nous stockons vos données',
                          color: const Color(0xFF8338EC),
                          content: null,
                          customWidget: _buildStorage(isMobile),
                        ),
                        _buildSection(
                          number: '6',
                          title: 'Partage des données',
                          color: AppColors.red,
                          content: _sharing,
                        ),
                        _buildSection(
                          number: '7',
                          title: 'Vos droits',
                          color: AppColors.yellow,
                          content: null,
                          customWidget: _buildRights(isMobile),
                        ),
                        _buildSection(
                          number: '8',
                          title: 'Données des mineurs',
                          color: const Color(0xFF3A86FF),
                          content: _minors,
                        ),
                        _buildSection(
                          number: '9',
                          title: 'Modifications de cette politique',
                          color: const Color(0xFF06D6A0),
                          content: _modifications,
                        ),
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

  // ── Header ──────────────────────────────────────────────────────
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
        // Logo
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
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.charcoal)),
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
          colors: [AppColors.charcoal, Color(0xFF2d2d4e)],
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
              color: AppColors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('DOCUMENT LÉGAL',
                style: TextStyle(color: AppColors.red, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 16),
          Text(
            '🔒 Politique de\nConfidentialité',
            style: TextStyle(
                fontSize: isMobile ? 28 : 36,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                height: 1.15),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dernière mise à jour : juin 2026 · Version 1.0',
            style: TextStyle(color: AppColors.gray, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nous prenons la protection de vos données très au sérieux. '
            'Ce document vous explique exactement comment nous utilisons '
            'vos informations.',
            style: TextStyle(color: AppColors.gray, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Section générique ────────────────────────────────────────────
  Widget _buildSection({
    required String number,
    required String title,
    required Color color,
    String? content,
    Widget? customWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
                            fontSize: 14))),
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

  // ── Données collectées ───────────────────────────────────────────
  Widget _buildDataCollected(bool isMobile) {
    final categories = [
      {
        'icon': '👤',
        'title': 'Données du Coach',
        'items': [
          'Nom complet — pour personnaliser l\'expérience',
          'Numéro de téléphone — identifiant unique de connexion',
          'Nom de l\'équipe — personnalisation de l\'application',
          'Mot de passe — stocké chiffré (hachage bcrypt), jamais en clair',
        ],
        'color': AppColors.red,
      },
      {
        'icon': '🏐',
        'title': 'Données des Joueurs',
        'items': [
          'Nom des joueurs',
          'Poste des joueurs',
          'Statut actif/inactif',
        ],
        'color': AppColors.yellow,
        'note': 'Ces données vous appartiennent. Vous êtes responsable '
            'd\'avoir le consentement de vos joueurs.',
      },
      {
        'icon': '📋',
        'title': 'Données de Planification',
        'items': [
          'Titres et contenus de vos plannings',
          'Séances, exercices, durées et domaines de jeu',
          'Dates et heures des séances',
        ],
        'color': const Color(0xFF3A86FF),
      },
      {
        'icon': '🤝',
        'title': 'Données de Collaboration',
        'items': [
          'Adresses email des membres du staff invités',
          'Activité sur les plannings partagés',
        ],
        'color': const Color(0xFF8338EC),
      },
    ];

    return Column(
      children: categories.map((cat) {
        final color = cat['color'] as Color;
        final items = cat['items'] as List<String>;
        final note = cat['note'] as String?;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(cat['icon'] as String,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(cat['title'] as String,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: color)),
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
                                  fontSize: 13,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  )),
              if (note != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(note,
                            style: const TextStyle(
                                color: AppColors.charcoal,
                                fontSize: 12,
                                height: 1.5,
                                fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Table pourquoi ───────────────────────────────────────────────
  Widget _buildWhyTable(bool isMobile) {
    final rows = [
      ['Identifiants (téléphone, mot de passe)', 'Authentification et sécurité'],
      ['Nom et équipe', 'Personnalisation de l\'expérience'],
      ['Joueurs et plannings', 'Fonctionnement du service principal'],
      ['Email des collaborateurs', 'Envoi des invitations'],
      ['Données techniques', 'Sécurité et amélioration du service'],
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10))),
          child: const Row(children: [
            Expanded(child: Text('Données',
                style: TextStyle(color: AppColors.white,
                    fontWeight: FontWeight.w700, fontSize: 13))),
            Expanded(child: Text('Finalité',
                style: TextStyle(color: AppColors.yellow,
                    fontWeight: FontWeight.w700, fontSize: 13))),
          ]),
        ),
        ...rows.asMap().entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: e.key.isEven
                    ? AppColors.grayXLight
                    : AppColors.white,
                borderRadius: e.key == rows.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(10))
                    : null,
              ),
              child: Row(children: [
                Expanded(child: Text(e.value[0],
                    style: const TextStyle(
                        color: AppColors.charcoal, fontSize: 13))),
                Expanded(child: Text(e.value[1],
                    style: const TextStyle(
                        color: AppColors.gray, fontSize: 13))),
              ]),
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF06D6A0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF06D6A0).withOpacity(0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅', style: TextStyle(fontSize: 16)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nous n\'utilisons vos données que pour faire fonctionner '
                  'VolleyPlan. Nous ne faisons pas de marketing sans votre consentement.',
                  style: TextStyle(color: AppColors.charcoal,
                      fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stockage ─────────────────────────────────────────────────────
  Widget _buildStorage(bool isMobile) {
    final infra = [
      {'icon': '🗄️', 'name': 'Supabase (PostgreSQL)',
       'desc': 'Base de données — serveurs dans l\'Union Européenne',
       'color': const Color(0xFF3A86FF)},
      {'icon': '🖥️', 'name': 'Render.com',
       'desc': 'Backend Flask — serveurs USA/Europe',
       'color': AppColors.red},
      {'icon': '🔥', 'name': 'Firebase Hosting',
       'desc': 'Frontend Flutter Web — CDN mondial',
       'color': AppColors.yellow},
      {'icon': '📧', 'name': 'Brevo',
       'desc': 'Envoi d\'emails — hébergé en Europe',
       'color': const Color(0xFF06D6A0)},
      {'icon': '🛡️', 'name': 'Cloudflare',
       'desc': 'Proxy et sécurité réseau',
       'color': const Color(0xFF8338EC)},
    ];

    final durations = [
      ['Compte et plannings', 'Aussi longtemps que votre compte est actif'],
      ['Compte supprimé', 'Suppression définitive sous 30 jours'],
      ['Logs techniques', '90 jours glissants'],
      ['Emails d\'invitation', 'Jusqu\'à expiration ou révocation'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Infrastructure technique',
            style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 14, color: AppColors.charcoal)),
        const SizedBox(height: 12),
        ...infra.map((item) {
          final color = item['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Text(item['icon'] as String,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item['name'] as String,
                    style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 13, color: color)),
                Text(item['desc'] as String,
                    style: const TextStyle(color: AppColors.gray,
                        fontSize: 12)),
              ])),
            ]),
          );
        }),
        const SizedBox(height: 20),
        const Text('Durée de conservation',
            style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 14, color: AppColors.charcoal)),
        const SizedBox(height: 12),
        ...durations.asMap().entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: e.key.isEven
                    ? AppColors.grayXLight
                    : AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Expanded(
                  flex: 2,
                  child: Text(e.value[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.charcoal)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(e.value[1],
                      style: const TextStyle(
                          color: AppColors.gray, fontSize: 13)),
                ),
              ]),
            )),
      ],
    );
  }

  // ── Droits ───────────────────────────────────────────────────────
  Widget _buildRights(bool isMobile) {
    final rights = [
      {'icon': '👁️', 'right': 'Accès',
       'desc': 'Obtenir une copie de vos données personnelles',
       'color': AppColors.red},
      {'icon': '✏️', 'right': 'Rectification',
       'desc': 'Corriger des données inexactes',
       'color': AppColors.yellow},
      {'icon': '🗑️', 'right': 'Suppression',
       'desc': 'Demander l\'effacement de votre compte et vos données',
       'color': const Color(0xFF3A86FF)},
      {'icon': '📦', 'right': 'Portabilité',
       'desc': 'Recevoir vos données dans un format lisible (JSON)',
       'color': const Color(0xFF06D6A0)},
      {'icon': '🚫', 'right': 'Opposition',
       'desc': 'Vous opposer à certains traitements',
       'color': const Color(0xFF8338EC)},
    ];

    return Column(
      children: [
        isMobile
            ? Column(children: rights.map((r) =>
                _buildRightCard(r, isMobile)).toList())
            : Wrap(
                spacing: 10, runSpacing: 10,
                children: rights.map((r) =>
                    SizedBox(width: 230,
                        child: _buildRightCard(r, isMobile)))
                    .toList()),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.red.withOpacity(0.2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📩 Comment exercer vos droits ?',
                  style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: AppColors.charcoal)),
              SizedBox(height: 8),
              Text(
                'Contactez-nous via WhatsApp ou notre page Facebook VolleyPlan. '
                'Nous nous engageons à répondre dans un délai de 30 jours.',
                style: TextStyle(color: AppColors.gray,
                    fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightCard(Map<String, dynamic> r, bool isMobile) {
    final color = r['color'] as Color;
    return Container(
      width: isMobile ? double.infinity : null,
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r['icon'] as String, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(r['right'] as String,
            style: TextStyle(fontWeight: FontWeight.w800,
                fontSize: 14, color: color)),
        const SizedBox(height: 4),
        Text(r['desc'] as String,
            style: const TextStyle(color: AppColors.gray,
                fontSize: 12, height: 1.4)),
      ]),
    );
  }

  // ── Contact ──────────────────────────────────────────────────────
  Widget _buildContactSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.charcoal, Color(0xFF2d2d4e)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📬 Contact',
            style: TextStyle(fontWeight: FontWeight.w800,
                fontSize: 18, color: AppColors.white)),
        const SizedBox(height: 12),
        const Text(
          'Pour toute question relative à vos données personnelles :',
          style: TextStyle(color: AppColors.gray, fontSize: 14),
        ),
        const SizedBox(height: 16),
        _contactItem('📘', 'Page Facebook', 'VolleyPlan'),
        _contactItem('💬', 'WhatsApp', 'Via la page Facebook'),
        _contactItem('📍', 'Adresse', 'Yaoundé, Cameroun'),
      ]),
    );
  }

  Widget _contactItem(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Text('$label : ',
            style: const TextStyle(color: AppColors.gray,
                fontSize: 13, fontWeight: FontWeight.w600)),
        Text(value,
            style: const TextStyle(color: AppColors.white, fontSize: 13)),
      ]),
    );
  }

  // ── Textes ───────────────────────────────────────────────────────
  static const _intro =
      'Bienvenue sur VolleyPlan. Nous prenons la protection de vos données '
      'personnelles très au sérieux. Cette politique vous explique quelles '
      'données nous collectons, pourquoi nous les collectons, comment nous '
      'les utilisons et quels sont vos droits.\n\n'
      'En utilisant VolleyPlan, vous acceptez les pratiques décrites dans ce document.';

  static const _whoWeAre =
      'VolleyPlan est une application web de planification d\'entraînements '
      'de volleyball, développée au Cameroun et accessible à l\'international.\n\n'
      'Contact : Pour toute question relative à vos données personnelles, '
      'contactez-nous via notre page Facebook VolleyPlan ou par WhatsApp.';

  static const _sharing =
      'Nous ne vendons, ne louons et ne partageons jamais vos données '
      'personnelles à des tiers à des fins commerciales.\n\n'
      '• Prestataires techniques : Supabase, Render, Firebase, Brevo accèdent '
      'techniquement à vos données pour faire fonctionner le service. Ils sont '
      'contractuellement tenus de protéger vos données.\n\n'
      '• Collaboration à votre initiative : quand vous invitez un collaborateur, '
      'il accède aux plannings que vous partagez. Vous contrôlez ces accès.\n\n'
      '• Obligations légales : nous pouvons divulguer vos données si la loi '
      'nous y oblige (décision judiciaire, autorité compétente).';

  static const _minors =
      'VolleyPlan n\'est pas destiné aux personnes de moins de 16 ans. '
      'Si vous êtes un coach travaillant avec des joueurs mineurs, vous êtes '
      'responsable de saisir leurs données conformément aux règles applicables '
      'dans votre pays (accord parental si nécessaire).';

  static const _modifications =
      'Nous pouvons mettre à jour cette politique occasionnellement. '
      'En cas de changement important, nous vous préviendrons via l\'application '
      'ou notre page Facebook. La date de dernière mise à jour est indiquée en '
      'haut de ce document.\n\n'
      'L\'utilisation continue de VolleyPlan après modification vaut acceptation '
      'de la nouvelle politique.';
}