import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:seo_renderer/seo_renderer.dart';
import '../models/blog_article.dart';
import '../utils/constants.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  String? _hoveredSlug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _buildHeader(context, l10n, isMobile),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(locale, isMobile),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 32,
                          vertical: 48,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextRenderer(
                              style: TextRendererStyle.header2,
                              child: Text(
                                locale == 'en' ? 'Latest Articles' : 'Derniers Articles',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildArticlesGrid(locale, isMobile),
                            const SizedBox(height: 64),
                            _buildCtaSection(l10n, isMobile),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.grayLight, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.red, AppColors.yellow],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('🏐', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'VolleyPlan',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.gray),
            label: Text(
              l10n.backLabel,
              style: const TextStyle(
                color: AppColors.gray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Section ─────────────────────────────────────────────────
  Widget _buildHero(String locale, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.charcoal, Color(0xFF24243E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.red.withOpacity(0.3)),
                ),
                child: Text(
                  locale == 'en' ? 'COACHING BLOG' : 'LE BLOG SPORTIF',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextRenderer(
                style: TextRendererStyle.header1,
                child: Text(
                  locale == 'en' ? 'The VolleyPlan Blog' : 'Le Blog VolleyPlan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 36 : 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextRenderer(
                style: TextRendererStyle.paragraph,
                child: Text(
                  locale == 'en'
                      ? 'Expert planning guides, tactical advice, and coaching strategies to structure your volleyball team\'s season.'
                      : 'Conseils de planification, tactiques de jeu et secrets de coaching pour structurer la saison de votre équipe de volleyball.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grid of Articles ─────────────────────────────────────────────
  Widget _buildArticlesGrid(String locale, bool isMobile) {
    final articles = BlogArticle.articles;

    if (isMobile) {
      return Column(
        children: articles.map((article) => _buildArticleCard(article, locale, true)).toList(),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: articles.map((article) => SizedBox(
        width: 340,
        child: _buildArticleCard(article, locale, false),
      )).toList(),
    );
  }

  // ── Article Card Widget ──────────────────────────────────────────
  Widget _buildArticleCard(BlogArticle article, String locale, bool isMobile) {
    final isHovered = _hoveredSlug == article.slug;
    final title = article.getTitle(locale);
    final category = article.getCategory(locale);
    final snippet = article.getSnippet(locale);

    // Dynamic color for category tag
    Color catColor = AppColors.red;
    if (article.slug.contains('reception')) {
      catColor = AppColors.yellow;
    } else if (article.slug.contains('collaboration')) {
      catColor = const Color(0xFF3A86FF);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredSlug = article.slug),
      onExit: (_) => setState(() => _hoveredSlug = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/blog/${article.slug}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? catColor.withOpacity(0.5) : AppColors.grayLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered ? catColor.withOpacity(0.08) : Colors.black.withOpacity(0.02),
                blurRadius: isHovered ? 20 : 8,
                offset: isHovered ? const Offset(0, 10) : const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful Gradient Thumbnail Header
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      catColor.withOpacity(0.7),
                      catColor.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    article.slug.contains('reception')
                        ? '🤲'
                        : article.slug.contains('collaboration')
                            ? '🤝'
                            : '📋',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: catColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time, size: 14, color: AppColors.gray),
                        const SizedBox(width: 4),
                        Text(
                          article.readTime,
                          style: const TextStyle(color: AppColors.gray, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextRenderer(
                      style: TextRendererStyle.header3,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextRenderer(
                      style: TextRendererStyle.paragraph,
                      child: Text(
                        snippet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.grayLight, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          article.date,
                          style: const TextStyle(color: AppColors.gray, fontSize: 11),
                        ),
                        const Spacer(),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.only(right: isHovered ? 0 : 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: catColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Call To Action Section ───────────────────────────────────────
  Widget _buildCtaSection(AppLocalizations l10n, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.charcoal, Color(0xFF24243E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '🏐',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.landingCtaTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.landingCtaSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Start Free Plan'
                  : 'Commencer gratuitement',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────
  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      color: AppColors.charcoal,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Text(
            l10n.landingFooterSlogan,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.landingFooterPassion,
            style: const TextStyle(
              color: AppColors.gray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
