import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                        _buildSection('1', l10n.termsSection1Title,
                            AppColors.red, l10n.termsSection1Content),
                        _buildSection('2', l10n.termsSection2Title,
                            AppColors.yellow, null,
                            customWidget:
                                _buildServiceDescription(l10n, isMobile)),
                        _buildSection('3', l10n.termsSection3Title,
                            const Color(0xFF3A86FF), null,
                            customWidget: _buildInscription(l10n, isMobile)),
                        _buildSection('4', l10n.termsSection4Title,
                            const Color(0xFF06D6A0), null,
                            customWidget: _buildAllowed(l10n, isMobile)),
                        _buildSection(
                            '5', l10n.termsSection5Title, AppColors.red, null,
                            customWidget: _buildForbidden(l10n, isMobile)),
                        _buildSection('6', l10n.termsSection6Title,
                            const Color(0xFF8338EC), l10n.termsSection6Content),
                        _buildSection('7', l10n.termsSection7Title,
                            AppColors.yellow, l10n.termsSection7Content),
                        _buildSection('8', l10n.termsSection8Title,
                            const Color(0xFF3A86FF), l10n.termsSection8Content),
                        _buildSection('9', l10n.termsSection9Title,
                            const Color(0xFF06D6A0), l10n.termsSection9Content),
                        _buildSection(
                            '10', l10n.termsSection10Title, AppColors.red, null,
                            customWidget: _buildEvolution(l10n, isMobile)),
                        _buildSection('11', l10n.termsSection11Title,
                            AppColors.yellow, l10n.termsSection11Content),
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

  // ── Header ───────────────────────────────────────────────────────
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
            child: Text(l10n.legalBadge,
                style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 16),
          Text(
            '📋 ${l10n.termsTitle}',
            style: TextStyle(
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.termsLastUpdate} · Version 1.0',
            style: const TextStyle(color: AppColors.gray, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.termsHeroIntro,
            style: const TextStyle(
                color: AppColors.gray, fontSize: 14, height: 1.6),
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
                width: 32,
                height: 32,
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
  Widget _buildServiceDescription(AppLocalizations l10n, bool isMobile) {
    final features = [
      '📅 ${l10n.termsFeature1}',
      '👥 ${l10n.termsFeature2}',
      '📊 ${l10n.termsFeature3}',
      '📄 ${l10n.termsFeature4}',
      '🤝 ${l10n.termsFeature5}',
      '💬 ${l10n.termsFeature6}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.substring(0, 2), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f.substring(2).trim(),
                        style: const TextStyle(
                            color: AppColors.gray, fontSize: 13, height: 1.5)),
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
            border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🚧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.termsBetaTitle,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.charcoal)),
                    SizedBox(height: 4),
                    Text(
                      l10n.termsBetaContent,
                      style: const TextStyle(
                          color: AppColors.gray, fontSize: 12, height: 1.5),
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
  Widget _buildInscription(AppLocalizations l10n, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSection(
            l10n.termsInscriptionReqTitle,
            [
              l10n.termsInscriptionReq1,
              l10n.termsInscriptionReq2,
              l10n.termsInscriptionReq3,
            ],
            AppColors.red),
        const SizedBox(height: 12),
        _buildSubSection(
            l10n.termsUserResponsibilityTitle,
            [
              l10n.termsUserResp1,
              l10n.termsUserResp2,
              l10n.termsUserResp3,
            ],
            const Color(0xFF3A86FF)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A86FF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ℹ️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.termsSingleAccountNote,
                  style: TextStyle(
                      color: AppColors.charcoal,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Allowed ──────────────────────────────────────────────────────
  Widget _buildAllowed(AppLocalizations l10n, bool isMobile) {
    final items = [
      l10n.termsAllowed1,
      l10n.termsAllowed2,
      l10n.termsAllowed3,
      l10n.termsAllowed4,
      l10n.termsAllowed5,
      l10n.termsAllowed6,
    ];
    return Column(
      children: items
          .map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              ))
          .toList(),
    );
  }

  // ── Forbidden ────────────────────────────────────────────────────
  Widget _buildForbidden(AppLocalizations l10n, bool isMobile) {
    final categories = [
      {
        'title': l10n.termsForbiddenIllegalTitle,
        'items': [
          l10n.termsForbiddenIllegal1,
          l10n.termsForbiddenIllegal2,
          l10n.termsForbiddenIllegal3,
        ],
        'color': AppColors.red,
      },
      {
        'title': l10n.termsForbiddenTechTitle,
        'items': [
          l10n.termsForbiddenTech1,
          l10n.termsForbiddenTech2,
          l10n.termsForbiddenTech3,
          l10n.termsForbiddenTech4,
        ],
        'color': const Color(0xFF8338EC),
      },
      {
        'title': l10n.termsForbiddenAbuseTitle,
        'items': [
          l10n.termsForbiddenAbuse1,
          l10n.termsForbiddenAbuse2,
          l10n.termsForbiddenAbuse3,
          l10n.termsForbiddenAbuse4,
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
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Evolution ────────────────────────────────────────────────────
  Widget _buildEvolution(AppLocalizations l10n, bool isMobile) {
    return Column(
      children: [
        _buildEvolutionCard(
          '🆓',
          l10n.termsEvolutionBetaTitle,
          l10n.termsEvolutionBetaContent,
          AppColors.red,
        ),
        const SizedBox(height: 10),
        _buildEvolutionCard(
          '📤',
          l10n.termsEvolutionExportTitle,
          l10n.termsEvolutionExportContent,
          AppColors.yellow,
        ),
        const SizedBox(height: 10),
        _buildEvolutionCard(
          '📢',
          l10n.termsEvolutionCguTitle,
          l10n.termsEvolutionCguContent,
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
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          const SizedBox(height: 6),
          Text(desc,
              style: const TextStyle(
                  color: AppColors.gray, fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }

  // ── SubSection helper ─────────────────────────────────────────────
  Widget _buildSubSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 7, right: 8),
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            color: AppColors.gray, fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── Contact ──────────────────────────────────────────────────────
  Widget _buildContactSection(AppLocalizations l10n, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.charcoal, Color(0xFF2d2d4e)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📬 ${l10n.termsContactTitle}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.white)),
        const SizedBox(height: 12),
        Text(l10n.termsContactSubtitle,
            style: const TextStyle(color: AppColors.gray, fontSize: 14)),
        const SizedBox(height: 16),
        _contactRow('📘', 'Facebook', 'Page VolleyPlan'),
        _contactRow('💬', 'WhatsApp', 'Via la page Facebook'),
        _contactRow('⚖️', 'Juridiction', 'Yaoundé, Cameroun'),
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
            style: const TextStyle(
                color: AppColors.gray,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: AppColors.white, fontSize: 13)),
        ),
      ]),
    );
  }
}
