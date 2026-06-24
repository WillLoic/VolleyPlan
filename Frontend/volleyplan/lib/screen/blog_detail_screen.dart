import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:seo_renderer/seo_renderer.dart';
import '../models/blog_article.dart';
import '../utils/constants.dart';

class BlogDetailScreen extends StatelessWidget {
  final String slug;
  const BlogDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Find the article
    final article = _findArticle(slug);

    if (article == null) {
      return _buildNotFound(context, l10n);
    }

    final title = article.getTitle(locale);
    final category = article.getCategory(locale);
    final paragraphs = article.getContent(locale);

    // Dynamic category color
    Color catColor = AppColors.red;
    if (article.slug.contains('reception')) {
      catColor = AppColors.yellow;
    } else if (article.slug.contains('collaboration')) {
      catColor = const Color(0xFF3A86FF);
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _buildHeader(context, l10n, isMobile),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildArticleHeader(context, article, title, category, catColor, isMobile),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 40,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Content Rendering
                            ...paragraphs.map((para) => _renderParagraph(para)),
                            const SizedBox(height: 50),
                            const Divider(color: AppColors.grayLight, height: 1),
                            const SizedBox(height: 48),
                            _buildCtaSection(context, l10n, isMobile),
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

  // Find the article by slug
  BlogArticle? _findArticle(String slug) {
    try {
      return BlogArticle.articles.firstWhere((a) => a.slug == slug);
    } catch (_) {
      return null;
    }
  }

  // Not Found view
  Widget _buildNotFound(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              const Text(
                'Article non trouvé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cet article n\'existe pas ou a été déplacé.',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/blog'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour au Blog'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
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
            onPressed: () => context.go('/blog'),
            icon: const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.gray),
            label: const Text(
              'Blog',
              style: TextStyle(
                color: AppColors.gray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Article Header Banner ─────────────────────────────────────────
  Widget _buildArticleHeader(
    BuildContext context,
    BlogArticle article,
    String title,
    String category,
    Color catColor,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      color: AppColors.charcoal,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 40 : 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back link
              GestureDetector(
                onTap: () => context.go('/blog'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_left_rounded, color: catColor, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? 'Back to blog'
                          : 'Retour au blog',
                      style: TextStyle(
                        color: catColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: catColor.withOpacity(0.3)),
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
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 14, color: AppColors.gray),
                  const SizedBox(width: 4),
                  Text(
                    article.readTime,
                    style: const TextStyle(color: AppColors.gray, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextRenderer(
                style: TextRendererStyle.header1,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('👤', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Text(
                    'VolleyPlan Team',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Text('•', style: TextStyle(color: AppColors.gray)),
                  const SizedBox(width: 16),
                  Text(
                    article.date,
                    style: const TextStyle(color: AppColors.gray, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Render markdown paragraphs and headers ───────────────────────
  Widget _renderParagraph(String para) {
    if (para.startsWith('### ')) {
      final headerText = para.substring(4);
      return Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 12),
        child: TextRenderer(
          style: TextRendererStyle.header3,
          child: Text(
            headerText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextRenderer(
        style: TextRendererStyle.paragraph,
        child: Text(
          para,
          style: const TextStyle(
            color: AppColors.gray,
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ),
    );
  }

  // ── Call To Action Section ───────────────────────────────────────
  Widget _buildCtaSection(BuildContext context, AppLocalizations l10n, bool isMobile) {
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
