import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        _buildHeroSection(l10n, isMobile),
                        const SizedBox(height: 40),
                        _buildSection(
                          number: '1',
                          title: l10n.privacySection1Title,
                          color: AppColors.red,
                          content: l10n.privacySection1Content,
                        ),
                        _buildSection(
                          number: '2',
                          title: l10n.privacySection2Title,
                          color: AppColors.yellow,
                          content: l10n.privacySection2Content,
                        ),
                        _buildSection(
                          number: '3',
                          title: l10n.privacySection3Title,
                          color: const Color(0xFF3A86FF),
                          content: null,
                          customWidget: _buildDataCollected(l10n, isMobile),
                        ),
                        _buildSection(
                          number: '4',
                          title: l10n.privacySection4Title,
                          color: const Color(0xFF06D6A0),
                          content: null,
                          customWidget: _buildWhyTable(l10n, isMobile),
                        ),
                        _buildSection(
                          number: '5',
                          title: l10n.privacySection5Title,
                          color: const Color(0xFF8338EC),
                          content: null,
                          customWidget: _buildStorage(l10n, isMobile),
                        ),
                        _buildSection(
                          number: '6',
                          title: l10n.privacySection6Title,
                          color: AppColors.red,
                          content: l10n.privacySection6Content,
                        ),
                        _buildSection(
                          number: '7',
                          title: l10n.privacySection7Title,
                          color: AppColors.yellow,
                          content: null,
                          customWidget: _buildRights(l10n, isMobile),
                        ),
                        _buildSection(
                          number: '8',
                          title: l10n.privacySection8Title,
                          color: const Color(0xFF3A86FF),
                          content: l10n.privacySection8Content,
                        ),
                        _buildSection(
                          number: '9',
                          title: l10n.privacySection9Title,
                          color: const Color(0xFF06D6A0),
                          content: l10n.privacySection9Content,
                        ),
                        _buildContactSection(l10n, isMobile),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border:
            Border(bottom: BorderSide(color: AppColors.grayLight, width: 1)),
      ),
      child: Row(children: [
        // Logo
        GestureDetector(
          onTap: () => context.go('/register'),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
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
          onPressed: () => context.go('/register'),
          icon: const Icon(Icons.arrow_back_rounded,
              size: 16, color: AppColors.gray),
          label: Text(l10n.backLabel,
              style: TextStyle(
                  color: AppColors.gray, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────
  Widget _buildHeroSection(AppLocalizations l10n, bool isMobile) {
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
            child: Text(l10n.legalBadge,
                style: TextStyle(
                    color: AppColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 16),
          Text(
            '🔒 ${l10n.privacyTitle}',
            style: TextStyle(
                fontSize: isMobile ? 28 : 36,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                height: 1.15),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.termsLastUpdate} · Version 1.0',
            style: const TextStyle(color: AppColors.gray, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.privacyHeroIntro,
            style: const TextStyle(
                color: AppColors.gray, fontSize: 14, height: 1.6),
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
                width: 32,
                height: 32,
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
  Widget _buildDataCollected(AppLocalizations l10n, bool isMobile) {
    final categories = [
      {
        'icon': '👤',
        'title': l10n.privacyDataCoachTitle,
        'items': [
          l10n.privacyDataCoachItem1,
          l10n.privacyDataCoachItem2,
          l10n.privacyDataCoachItem3,
          l10n.privacyDataCoachItem4,
        ],
        'color': AppColors.red,
      },
      {
        'icon': '🏐',
        'title': l10n.privacyDataJoueursTitle,
        'items': [
          l10n.privacyDataJoueursItem1,
          l10n.privacyDataJoueursItem2,
          l10n.privacyDataJoueursItem3,
        ],
        'color': AppColors.yellow,
        'note': l10n.privacyDataJoueursNote,
      },
      {
        'icon': '📋',
        'title': l10n.privacyDataPlanTitle,
        'items': [
          l10n.privacyDataPlanItem1,
          l10n.privacyDataPlanItem2,
          l10n.privacyDataPlanItem3,
        ],
        'color': const Color(0xFF3A86FF),
      },
      {
        'icon': '🤝',
        'title': l10n.privacyDataCollabTitle,
        'items': [
          l10n.privacyDataCollabItem1,
          l10n.privacyDataCollabItem2,
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
                          width: 5,
                          height: 5,
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
  Widget _buildWhyTable(AppLocalizations l10n, bool isMobile) {
    final rows = [
      [l10n.privacyWhyRow1Data, l10n.privacyWhyRow1Purpose],
      [l10n.privacyWhyRow2Data, l10n.privacyWhyRow2Purpose],
      [l10n.privacyWhyRow3Data, l10n.privacyWhyRow3Purpose],
      [l10n.privacyWhyRow4Data, l10n.privacyWhyRow4Purpose],
      [l10n.privacyWhyRow5Data, l10n.privacyWhyRow5Purpose],
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10))),
          child: Row(children: [
            Expanded(
                child: Text(l10n.privacyWhyHeaderData,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13))),
            Expanded(
                child: Text(l10n.privacyWhyHeaderPurpose,
                    style: const TextStyle(
                        color: AppColors.yellow,
                        fontWeight: FontWeight.w700,
                        fontSize: 13))),
          ]),
        ),
        ...rows.asMap().entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: e.key.isEven ? AppColors.grayXLight : AppColors.white,
                borderRadius: e.key == rows.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(10))
                    : null,
              ),
              child: Row(children: [
                Expanded(
                    child: Text(e.value[0],
                        style: const TextStyle(
                            color: AppColors.charcoal, fontSize: 13))),
                Expanded(
                    child: Text(e.value[1],
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
            border: Border.all(color: const Color(0xFF06D6A0).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.privacyWhyNote,
                  style: const TextStyle(
                      color: AppColors.charcoal,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stockage ─────────────────────────────────────────────────────
  Widget _buildStorage(AppLocalizations l10n, bool isMobile) {
    final infra = [
      {
        'icon': '🗄️',
        'name': 'Supabase (PostgreSQL)',
        'desc': l10n.privacyStorageDb,
        'color': const Color(0xFF3A86FF)
      },
      {
        'icon': '🖥️',
        'name': 'Render.com',
        'desc': l10n.privacyStorageBackend,
        'color': AppColors.red
      },
      {
        'icon': '🔥',
        'name': 'Firebase Hosting',
        'desc': l10n.privacyStorageFrontend,
        'color': AppColors.yellow
      },
      {
        'icon': '📧',
        'name': 'Brevo',
        'desc': l10n.privacyStorageEmail,
        'color': const Color(0xFF06D6A0)
      },
      {
        'icon': '🛡️',
        'name': 'Cloudflare',
        'desc': l10n.privacyStorageProxy,
        'color': const Color(0xFF8338EC)
      },
    ];

    final durations = [
      [l10n.privacyStorageDurRow1Label, l10n.privacyStorageDurRow1Value],
      [l10n.privacyStorageDurRow2Label, l10n.privacyStorageDurRow2Value],
      [l10n.privacyStorageDurRow3Label, l10n.privacyStorageDurRow3Value],
      [l10n.privacyStorageDurRow4Label, l10n.privacyStorageDurRow4Value],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.privacyStorageInfraTitle,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.charcoal)),
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
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item['name'] as String,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: color)),
                    Text(item['desc'] as String,
                        style: const TextStyle(
                            color: AppColors.gray, fontSize: 12)),
                  ])),
            ]),
          );
        }),
        const SizedBox(height: 20),
        Text(l10n.privacyStorageDurationTitle,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.charcoal)),
        const SizedBox(height: 12),
        ...durations.asMap().entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: e.key.isEven ? AppColors.grayXLight : AppColors.white,
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
                      style:
                          const TextStyle(color: AppColors.gray, fontSize: 13)),
                ),
              ]),
            )),
      ],
    );
  }

  // ── Droits ───────────────────────────────────────────────────────
  Widget _buildRights(AppLocalizations l10n, bool isMobile) {
    final rights = [
      {
        'icon': '👁️',
        'right': l10n.privacyRightsAccess,
        'desc': l10n.privacyRightsAccessDesc,
        'color': AppColors.red
      },
      {
        'icon': '✏️',
        'right': l10n.privacyRightsRectif,
        'desc': l10n.privacyRightsRectifDesc,
        'color': AppColors.yellow
      },
      {
        'icon': '🗑️',
        'right': l10n.privacyRightsDelete,
        'desc': l10n.privacyRightsDeleteDesc,
        'color': const Color(0xFF3A86FF)
      },
      {
        'icon': '📦',
        'right': l10n.privacyRightsPortability,
        'desc': l10n.privacyRightsPortabilityDesc,
        'color': const Color(0xFF06D6A0)
      },
      {
        'icon': '🚫',
        'right': l10n.privacyRightsOpposition,
        'desc': l10n.privacyRightsOppositionDesc,
        'color': const Color(0xFF8338EC)
      },
    ];

    return Column(
      children: [
        isMobile
            ? Column(
                children:
                    rights.map((r) => _buildRightCard(r, isMobile)).toList())
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: rights
                    .map((r) => SizedBox(
                        width: 230, child: _buildRightCard(r, isMobile)))
                    .toList()),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.red.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.privacyRightsExerciseTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.charcoal)),
              const SizedBox(height: 8),
              Text(
                l10n.privacyRightsExerciseContent,
                style: const TextStyle(
                    color: AppColors.gray, fontSize: 13, height: 1.5),
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
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: color)),
        const SizedBox(height: 4),
        Text(r['desc'] as String,
            style: const TextStyle(
                color: AppColors.gray, fontSize: 12, height: 1.4)),
      ]),
    );
  }

  // ── Contact ──────────────────────────────────────────────────────
  Widget _buildContactSection(AppLocalizations l10n, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.charcoal, Color(0xFF2d2d4e)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📬 ${l10n.privacyContactTitle}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.white)),
        const SizedBox(height: 12),
        Text(l10n.privacyContactSubtitle,
            style: const TextStyle(color: AppColors.gray, fontSize: 14)),
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
            style: const TextStyle(
                color: AppColors.gray,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
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
