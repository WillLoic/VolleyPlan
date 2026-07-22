import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:seo_renderer/seo_renderer.dart';
import '../utils/constants.dart';
import '../widgets/vp_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LANDING SCREEN COMPLET
// ─────────────────────────────────────────────────────────────────────────────
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  // Controllers d'animation d'origine
  late AnimationController _heroController;
  late AnimationController _ballController;
  late AnimationController _floatController;
  late AnimationController _statsController;

  // Animations Hero
  late Animation<double> _badgeFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;
  late Animation<Offset> _ctaSlide;
  late Animation<double> _ctaFade;

  // Animation ballon volant
  late Animation<double> _ballX;
  late Animation<double> _ballY;
  late Animation<double> _ballRotation;
  late Animation<double> _ballScale;

  // Animation floating cards
  late Animation<double> _float1;
  late Animation<double> _float2;

  // Animation stats counter
  late Animation<double> _statsProgress;

  final ScrollController _scrollController = ScrollController();
  bool _statsVisible = false;
  bool _showFloatingMenu = false;

  // Clés globales pour la navigation (Ancres)
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _whyKey = GlobalKey();
  final GlobalKey _guideKey = GlobalKey();
  final GlobalKey _testimonialsKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // Getter pour accéder aux traductions dans toutes les méthodes de la classe
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();

    // ── Hero entrance ──────────────────────────────────────────────
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _badgeFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _heroController,
          curve: const Interval(0.0, 0.25, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _heroController,
            curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic)));
    _titleFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOut)));
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _heroController,
                curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic)));
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut)));
    _ctaSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _heroController,
            curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic)));
    _ctaFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut)));

    // ── Ballon volleyball animé ────────────────────────────────────
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _ballX = Tween<double>(begin: -0.15, end: 1.15).animate(
        CurvedAnimation(parent: _ballController, curve: Curves.easeInOut));
    _ballY = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.55, end: 0.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.15, end: 0.55)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_ballController);
    _ballRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
        CurvedAnimation(parent: _ballController, curve: Curves.linear));
    _ballScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.7, end: 1.1)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.1, end: 0.7)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_ballController);

    // ── Floating cards ─────────────────────────────────────────────
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _float1 = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _float2 = Tween<double>(begin: 6, end: -6).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    // ── Stats counter ──────────────────────────────────────────────
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _statsProgress =
        CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _heroController.forward();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Gestion du déclenchement des stats
    if (!_statsVisible && _scrollController.offset > 400) {
      setState(() => _statsVisible = true);
      _statsController.forward();
    }

    // Gestion de l'affichage du menu burger flottant
    if (_scrollController.offset > 350 && !_showFloatingMenu) {
      setState(() => _showFloatingMenu = true);
    } else if (_scrollController.offset <= 350 && _showFloatingMenu) {
      setState(() => _showFloatingMenu = false);
    }
  }

  void _scrollToSection(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showNavigationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ListView(
            shrinkWrap:
                true, // Permet au ListView de ne prendre que la place nécessaire
            physics:
                const ClampingScrollPhysics(), // Évite les rebonds bizarres en fin de liste
            children: [
              Text(l10n.landingMenuTitle,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.charcoal)),
              const SizedBox(height: 12),
              _buildSheetItem(l10n.homeLabel, Icons.home_rounded, _heroKey),
              _buildSheetItem(
                  l10n.landingMenuAbout, Icons.info_outline_rounded, _aboutKey),
              _buildSheetItem(
                  l10n.landingMenuHow, Icons.alt_route_rounded, _howItWorksKey),
              _buildSheetItem(
                  l10n.landingMenuWhy, Icons.gpp_good_rounded, _whyKey),
              _buildSheetItem(l10n.landingMenuGuide,
                  Icons.play_circle_outline_rounded, _guideKey),
              _buildSheetItem(l10n.landingMenuTestimonials,
                  Icons.comment_rounded, _testimonialsKey),
              _buildSheetItem(
                  l10n.landingMenuFaq, Icons.help_outline_rounded, _faqKey),
              const Divider(color: AppColors.grayLight, height: 1),
              ListTile(
                leading: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.red),
                title: const Text('Tarifs',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/tarifs');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.article_rounded, color: AppColors.red),
                title: const Text('Blog',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/blog');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetItem(String label, IconData icon, GlobalKey targetKey) {
    return ListTile(
      leading: Icon(icon, color: AppColors.red),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.charcoal)),
      onTap: () {
        Navigator.pop(context);
        _scrollToSection(targetKey);
      },
    );
  }

  @override
  void dispose() {
    _heroController.dispose();
    _ballController.dispose();
    _floatController.dispose();
    _statsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite, //[cite: 1]
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController, //[cite: 1]
            child: Column(
              children: [
                Container(key: _heroKey, child: _buildHeader(context)),
                _buildHero(context), //[cite: 1]
                _buildStats(context), //[cite: 1]
                _AboutSection(key: _aboutKey),
                _HowItWorksSection(key: _howItWorksKey),
                _WhyVolleyPlanSection(key: _whyKey),
                _buildFeatures(context, l10n), //[cite: 1]
                _GuideSection(key: _guideKey),
                _TestimonialsSection(key: _testimonialsKey),
                _FAQSection(key: _faqKey),
                _buildCTA(context), //[cite: 1]
                _buildFooter(), //[cite: 1]
              ],
            ),
          ),

          // Menu Flottant en bas à droite (uniquement au scroll)
          if (_showFloatingMenu)
            Positioned(
              bottom: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'btn_up',
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.charcoal,
                    elevation: 4,
                    onPressed: () => _scrollToSection(_heroKey),
                    child: const Icon(Icons.arrow_upward_rounded),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'btn_burger',
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    elevation: 6,
                    onPressed: _showNavigationSheet,
                    child: const Icon(Icons.menu_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768; //[cite: 1]
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40, vertical: 18), //[cite: 1]
      decoration: const BoxDecoration(
        color: AppColors.white, //[cite: 1]
        border: Border(
            bottom:
                BorderSide(color: AppColors.grayLight, width: 1)), //[cite: 1]
      ),
      child: Row(
        children: [
          _buildLogo(), //[cite: 1]
          const Spacer(), //[cite: 1]
          if (!isMobile) ...[
            TextButton(
              onPressed: _showNavigationSheet,
              style: TextButton.styleFrom(foregroundColor: AppColors.charcoal),
              child: Row(
                children: [
                  const Icon(Icons.menu_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(l10n.navMenu,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            TextButton(
              onPressed: () => context.push('/login'), //[cite: 1]
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.charcoal), //[cite: 1]
              child: Text(l10n.loginAction, //[cite: 1]
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)), //[cite: 1]
            ),
            const SizedBox(width: 12), //[cite: 1]
          ],
          VpButton(
            label: isMobile ? l10n.navMenu : l10n.registerAction,
            small: true, //[cite: 1]
            onPressed: () =>
                isMobile ? _showNavigationSheet() : context.push('/register'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return LinkRenderer(
      href: '/',
      text: 'VolleyPlan', // Texte alternatif pour le lien du logo
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.red, AppColors.yellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                  color: AppColors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child:
              const Center(child: Text('🏐', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 10),
        const Text('VolleyPlan',
            style: TextStyle(
                color: AppColors.charcoal,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: -0.5)),
      ]),
    );
  }

  // ─── HERO ──────────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    final size = MediaQuery.of(context).size; //[cite: 1]
    final isMobile = size.width < 768; //[cite: 1]

    return Container(
      width: double.infinity, //[cite: 1]
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, //[cite: 1]
          end: Alignment.bottomCenter, //[cite: 1]
          colors: [AppColors.white, AppColors.offWhite], //[cite: 1]
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildGridBackground()), //[cite: 1]
          _buildAnimatedBall(size), //[cite: 1]
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 60, //[cite: 1]
                vertical: isMobile ? 50 : 80), //[cite: 1]
            child: isMobile
                ? _buildHeroMobile(context) //[cite: 1]
                : _buildHeroDesktop(context), //[cite: 1]
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(painter: _GridPainter()); //[cite: 1]
  }

  Widget _buildAnimatedBall(Size size) {
    return AnimatedBuilder(
      animation: _ballController, //[cite: 1]
      builder: (context, child) {
        return Positioned(
          left: _ballX.value * size.width - 30, //[cite: 1]
          top: _ballY.value * (size.height * 0.5), //[cite: 1]
          child: Transform.rotate(
            angle: _ballRotation.value, //[cite: 1]
            child: Transform.scale(
              scale: _ballScale.value, //[cite: 1]
              child: Opacity(
                opacity: 0.18, //[cite: 1]
                child: Text('🏐',
                    style: TextStyle(
                        fontSize: size.width < 768 ? 48 : 72)), //[cite: 1]
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, //[cite: 1]
      children: [
        Expanded(flex: 5, child: _buildHeroText(context)), //[cite: 1]
        const SizedBox(width: 60), //[cite: 1]
        Expanded(flex: 4, child: _buildHeroVisual()), //[cite: 1]
      ],
    );
  }

  Widget _buildHeroMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, //[cite: 1]
      children: [
        _buildHeroText(context), //[cite: 1]
        const SizedBox(height: 48), //[cite: 1]
        Center(child: _buildHeroVisual()), //[cite: 1]
      ],
    );
  }

  Widget _buildHeroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, //[cite: 1]
      children: [
        FadeTransition(
          opacity: _badgeFade, //[cite: 1]
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 7), //[cite: 1]
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.08), //[cite: 1]
              borderRadius: BorderRadius.circular(30), //[cite: 1]
              border: Border.all(
                  color: AppColors.red.withOpacity(0.2), width: 1), //[cite: 1]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, //[cite: 1]
              children: [
                Container(
                    width: 6, //[cite: 1]
                    height: 6, //[cite: 1]
                    decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle)), //[cite: 1]
                const SizedBox(width: 8), //[cite: 1]
                Text(l10n.landingHeroBadge,
                    style: TextStyle(
                        color: AppColors.red, //[cite: 1]
                        fontSize: 11, //[cite: 1]
                        fontWeight: FontWeight.w800, //[cite: 1]
                        letterSpacing: 1.5)), //[cite: 1]
              ],
            ),
          ),
        ),
        const SizedBox(height: 24), //[cite: 1]

        SlideTransition(
          position: _titleSlide, //[cite: 1]
          child: FadeTransition(
            opacity: _titleFade, //[cite: 1]
            child: TextRenderer(
              style: TextRendererStyle.header1,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 52, //[cite: 1]
                      fontWeight: FontWeight.w900, //[cite: 1]
                      color: AppColors.charcoal, //[cite: 1]
                      height: 1.05, //[cite: 1]
                      letterSpacing: -1.5), //[cite: 1]
                  children: [
                    TextSpan(text: l10n.landingHeroTitle1), //[cite: 1]
                    TextSpan(
                        text: l10n.landingHeroTitle2,
                        style:
                            const TextStyle(color: AppColors.red)), //[cite: 1]
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24), //[cite: 1]

        SlideTransition(
          position: _subtitleSlide, //[cite: 1]
          child: FadeTransition(
            opacity: _subtitleFade, //[cite: 1]
            child: TextRenderer(
              style: TextRendererStyle.paragraph,
              child: Text(
                l10n.landingHeroSubtitle, //[cite: 1]
                style: TextStyle(
                    fontSize: 17, //[cite: 1]
                    color: AppColors.gray, //[cite: 1]
                    height: 1.6, //[cite: 1]
                    fontWeight: FontWeight.w400), //[cite: 1]
              ),
            ),
          ),
        ),
        const SizedBox(height: 40), //[cite: 1]

        SlideTransition(
          position: _ctaSlide, //[cite: 1]
          child: FadeTransition(
            opacity: _ctaFade, //[cite: 1]
            child: // REMPLACE LE ROW PAR CE WRAP RESPONSIVE
                Wrap(
              spacing:
                  16, // Équivalent du SizedBox(width: 16) entre les boutons
              runSpacing:
                  12, // Espace vertical automatique si le bouton "Connexion" passe en dessous
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LinkRenderer(
                  text: l10n.landingCtaStart, // Le texte du lien
                  href: '/register', // L'URL de destination
                  child: VpButton(
                    label: l10n.landingCtaStart,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push('/register'),
                  ),
                ),
                LinkRenderer(
                  text: l10n.loginAction, // Le texte du lien
                  href: '/login', // L'URL de destination
                  child: TextButton.icon(
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.login_rounded,
                        size: 16, color: AppColors.charcoal),
                    label: Text(
                      l10n.loginAction,
                      style: const TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    final l10n = AppLocalizations.of(context)!;
    return ImageRenderer(
      alt:
          'Aperçu de l\'interface de VolleyPlan montrant la création de planning et les bilans de performance.',
      child: AnimatedBuilder(
        animation: _floatController, //[cite: 1]
        builder: (context, child) {
          return SizedBox(
            height: 420, //[cite: 1]
            child: Stack(
              clipBehavior: Clip.none, //[cite: 1]
              children: [
                Positioned(
                  top: 20 + _float1.value, //[cite: 1]
                  left: 0, //[cite: 1]
                  right: 40, //[cite: 1]
                  child: _buildFloatingCard(
                    title: l10n.landingVisualPlanTitle, //[cite: 1]
                    subtitle: l10n.landingVisualPlanSub, //[cite: 1]
                    icon: Icons.calendar_month_rounded, //[cite: 1]
                    color: AppColors.red, //[cite: 1]
                    tags: [
                      l10n.domaineService,
                      l10n.domaineAttaque,
                      l10n.domaineDefense
                    ], //[cite: 1]
                  ),
                ),
                Positioned(
                  top: 160 + _float2.value, //[cite: 1]
                  right: 0, //[cite: 1]
                  left: 30, //[cite: 1]
                  child: _buildBilanCard(l10n), //[cite: 1]
                ),
                Positioned(
                  bottom: 30 + _float1.value * 0.5, //[cite: 1]
                  left: 10, //[cite: 1]
                  child: _buildBadgeCard(
                      '👥',
                      l10n.landingVisualPlayersCount,
                      l10n.landingVisualRosterActive,
                      AppColors.yellow), //[cite: 1]
                ),
                Positioned(
                  bottom: 60 + _float2.value * 0.5, //[cite: 1]
                  right: 10, //[cite: 1]
                  child: _buildBadgeCard('📄', l10n.landingVisualExportPdf,
                      l10n.landingVisualShareable, AppColors.red), //[cite: 1]
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.all(20), //[cite: 1]
      decoration: BoxDecoration(
        color: AppColors.white, //[cite: 1]
        borderRadius: BorderRadius.circular(20), //[cite: 1]
        boxShadow: [
          BoxShadow(
              color: AppColors.charcoal.withOpacity(0.08), //[cite: 1]
              blurRadius: 24, //[cite: 1]
              offset: const Offset(0, 8)), //[cite: 1]
          BoxShadow(
              color: color.withOpacity(0.06), //[cite: 1]
              blurRadius: 40, //[cite: 1]
              spreadRadius: 4), //[cite: 1]
        ],
        border: Border.all(color: AppColors.grayLight, width: 1), //[cite: 1]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, //[cite: 1]
        children: [
          Row(children: [
            Container(
              width: 36, //[cite: 1]
              height: 36, //[cite: 1]
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), //[cite: 1]
                  borderRadius: BorderRadius.circular(10)), //[cite: 1]
              child: Icon(icon, color: color, size: 18), //[cite: 1]
            ),
            const SizedBox(width: 12), //[cite: 1]
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //[cite: 1]
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, //[cite: 1]
                            fontSize: 14, //[cite: 1]
                            color: AppColors.charcoal)), //[cite: 1]
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.gray)), //[cite: 1]
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3), //[cite: 1]
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), //[cite: 1]
                borderRadius: BorderRadius.circular(20), //[cite: 1]
              ),
              child: Text(l10n.landingVisualActive,
                  style: TextStyle(
                      color: color, //[cite: 1]
                      fontSize: 10, //[cite: 1]
                      fontWeight: FontWeight.w700)), //[cite: 1]
            ),
          ]),
          const SizedBox(height: 14), //[cite: 1]
          Wrap(
            spacing: 6, //[cite: 1]
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4), //[cite: 1]
                      decoration: BoxDecoration(
                        color: AppColors.grayXLight, //[cite: 1]
                        borderRadius: BorderRadius.circular(20), //[cite: 1]
                      ),
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 11, //[cite: 1]
                              color: AppColors.charcoal, //[cite: 1]
                              fontWeight: FontWeight.w600)), //[cite: 1]
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBilanCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18), //[cite: 1]
      decoration: BoxDecoration(
        color: AppColors.charcoal, //[cite: 1]
        borderRadius: BorderRadius.circular(18), //[cite: 1]
        boxShadow: [
          BoxShadow(
              color: AppColors.charcoal.withOpacity(0.25), //[cite: 1]
              blurRadius: 20, //[cite: 1]
              offset: const Offset(0, 8)), //[cite: 1]
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, //[cite: 1]
        children: [
          Row(children: [
            const Icon(Icons.analytics_rounded, //[cite: 1]
                color: AppColors.yellow,
                size: 16), //[cite: 1]
            SizedBox(width: 8), //[cite: 1]
            Text(l10n.landingVisualReportTitle,
                style: const TextStyle(
                    color: AppColors.white, //[cite: 1]
                    fontWeight: FontWeight.w700, //[cite: 1]
                    fontSize: 12)), //[cite: 1]
          ]),
          const SizedBox(height: 14), //[cite: 1]
          _buildMiniBar(l10n.domaineService, 0.72, AppColors.red), //[cite: 1]
          const SizedBox(height: 6), //[cite: 1]
          _buildMiniBar(
              l10n.domaineAttaque, 0.58, AppColors.yellow), //[cite: 1]
          const SizedBox(height: 6), //[cite: 1]
          _buildMiniBar(
              l10n.domaineDefense, 0.45, const Color(0xFF06D6A0)), //[cite: 1]
          const SizedBox(height: 6), //[cite: 1]
          _buildMiniBar(
              l10n.domainePhysique, 0.30, const Color(0xFF3A86FF)), //[cite: 1]
        ],
      ),
    );
  }

  Widget _buildMiniBar(String label, double value, Color color) {
    return Row(children: [
      SizedBox(
        width: 52, //[cite: 1]
        child: Text(label,
            style: const TextStyle(
                color: AppColors.gray,
                fontSize: 10,
                fontWeight: FontWeight.w500)), //[cite: 1]
      ),
      const SizedBox(width: 8), //[cite: 1]
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99), //[cite: 1]
          child: LinearProgressIndicator(
            value: value, //[cite: 1]
            backgroundColor: Colors.white.withOpacity(0.08), //[cite: 1]
            valueColor: AlwaysStoppedAnimation<Color>(color), //[cite: 1]
            minHeight: 6, //[cite: 1]
          ),
        ),
      ),
      const SizedBox(width: 8), //[cite: 1]
      Text('${(value * 100).toInt()}%',
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700)), //[cite: 1]
    ]);
  }

  Widget _buildBadgeCard(String emoji, String title, String sub, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10), //[cite: 1]
      decoration: BoxDecoration(
        color: AppColors.white, //[cite: 1]
        borderRadius: BorderRadius.circular(14), //[cite: 1]
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.12), //[cite: 1]
              blurRadius: 16, //[cite: 1]
              offset: const Offset(0, 4)), //[cite: 1]
        ],
        border:
            Border.all(color: color.withOpacity(0.2), width: 1.5), //[cite: 1]
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        //[cite: 1]
        Text(emoji, style: const TextStyle(fontSize: 20)), //[cite: 1]
        const SizedBox(width: 10), //[cite: 1]
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //[cite: 1]
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, //[cite: 1]
                  fontSize: 12, //[cite: 1]
                  color: AppColors.charcoal)), //[cite: 1]
          Text(sub,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.gray)), //[cite: 1]
        ]),
      ]),
    );
  }

  // ─── STATS ─────────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 768; //[cite: 1]
    final stats = [
      {
        'value': 500,
        'suffix': '+',
        'label': l10n.landingStatCoaches,
        'icon': '👨‍💼'
      }, //[cite: 1]
      {
        'value': 3200,
        'suffix': '+',
        'label': l10n.landingStatPlannings,
        'icon': '📋'
      }, //[cite: 1]
      {
        'value': 98,
        'suffix': '%',
        'label': l10n.landingStatSatisfaction,
        'icon': '⭐'
      }, //[cite: 1]
      {
        'value': 12,
        'suffix': 'k+',
        'label': l10n.landingStatSessions,
        'icon': '📅'
      }, //[cite: 1]
    ];

    return Container(
      padding: EdgeInsets.symmetric(
          vertical: 60, horizontal: isMobile ? 24 : 60), //[cite: 1]
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.charcoal, //[cite: 1]
            Color(0xFF2d2d4e), //[cite: 1]
          ],
        ),
      ),
      child: isMobile
          ? Wrap(
              spacing: 20, //[cite: 1]
              runSpacing: 24, //[cite: 1]
              alignment: WrapAlignment.center, //[cite: 1]
              children: stats
                  .map((s) => SizedBox(
                      width: 140, //[cite: 1]
                      child: _buildStatItem(s, isMobile))) //[cite: 1]
                  .toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, //[cite: 1]
              children: stats
                  .map((s) =>
                      Expanded(child: _buildStatItem(s, isMobile))) //[cite: 1]
                  .toList(),
            ),
    );
  }

  Widget _buildStatItem(Map<String, dynamic> s, bool isMobile) {
    return AnimatedBuilder(
      animation: _statsProgress, //[cite: 1]
      builder: (context, child) {
        final val =
            ((s['value'] as int) * _statsProgress.value).toInt(); //[cite: 1]
        return TextRenderer(
          child: Column(children: [
            Text(s['icon'] as String,
                style: TextStyle(fontSize: isMobile ? 28 : 36)),
            const SizedBox(height: 10),
            Text(
              '$val${s['suffix']}',
              style: TextStyle(
                  fontSize: isMobile ? 30 : 42,
                  fontWeight: FontWeight.w900,
                  color: AppColors.yellow,
                  letterSpacing: -1),
            ),
            const SizedBox(height: 4),
            Text(s['label'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
        );
      },
    );
  }

  // ─── FEATURES ──────────────────────────────────────────────────────────────
  Widget _buildFeatures(BuildContext context, AppLocalizations l10n) {
    final isMobile = MediaQuery.of(context).size.width < 768; //[cite: 1]
    final features = [
      {
        'icon': Icons.calendar_month_rounded, //[cite: 1]
        'color': AppColors.red, //[cite: 1]
        'title': l10n.featurePlanningTitle, //[cite: 1]
        'desc': l10n.featurePlanningDesc, //[cite: 1]
        'tag': l10n.landingFeatureTagCreation, //[cite: 1]
      },
      {
        'icon': Icons.people_alt_rounded, //[cite: 1]
        'color': const Color(0xFF3A86FF), //[cite: 1]
        'title': l10n.featurePlayersTitle, //[cite: 1]
        'desc': l10n.featurePlayersDesc, //[cite: 1]
        'tag': l10n.landingFeatureTagPlayers, //[cite: 1]
      },
      {
        'icon': Icons.analytics_rounded, //[cite: 1]
        'color': AppColors.yellow, //[cite: 1]
        'title': l10n.featureAnalyseTitle, //[cite: 1]
        'desc': l10n.featureAnalyseDesc, //[cite: 1]
        'tag': l10n.landingFeatureTagAnalyse, //[cite: 1]
      },
      {
        'icon': Icons.picture_as_pdf_rounded, //[cite: 1]
        'color': const Color(0xFF06D6A0), //[cite: 1]
        'title': l10n.featureExportTitle, //[cite: 1]
        'desc': l10n.featureExportDesc, //[cite: 1]
        'tag': l10n.landingFeatureTagShare, //[cite: 1]
      },
      {
        'icon': Icons.group_add_rounded, //[cite: 1]
        'color': const Color(0xFF8338EC), //[cite: 1]
        'title': l10n.featureStaffTitle, //[cite: 1]
        'desc': l10n.featureStaffDesc, //[cite: 1]
        'tag': l10n.landingFeatureTagTeam, //[cite: 1]
      },
      {
        'icon': Icons.fitness_center_rounded, //[cite: 1]
        'color': const Color(0xFFEF476F), //[cite: 1]
        'title': l10n.featurePhysiqueTitle, //[cite: 1]
        'desc': l10n.featurePhysiqueDesc, //[cite: 1]
        'tag': l10n.landingFeatureTagPhysique, //[cite: 1]
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
          vertical: 80, horizontal: isMobile ? 24 : 60), //[cite: 1]
      color: AppColors.offWhite, //[cite: 1]
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6), //[cite: 1]
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.08), //[cite: 1]
            borderRadius: BorderRadius.circular(20), //[cite: 1]
          ),
          child: Text(l10n.landingFeatureLabel,
              style: const TextStyle(
                  color: AppColors.red, //[cite: 1]
                  fontSize: 11, //[cite: 1]
                  fontWeight: FontWeight.w800, //[cite: 1]
                  letterSpacing: 2)), //[cite: 1]
        ),
        const SizedBox(height: 16), //[cite: 1]
        TextRenderer(
          style: TextRendererStyle.header2,
          child: Text(
            isMobile
                ? l10n.landingFeatureHeadingMobile //[cite: 1]
                : l10n.landingFeatureHeading, //[cite: 1]
            textAlign: TextAlign.center, //[cite: 1]
            style: TextStyle(
                fontSize: isMobile ? 26 : 36, //[cite: 1]
                fontWeight: FontWeight.w900, //[cite: 1]
                color: AppColors.charcoal, //[cite: 1]
                letterSpacing: -0.8), //[cite: 1]
          ),
        ),
        const SizedBox(height: 10), //[cite: 1]
        TextRenderer(
          style: TextRendererStyle.paragraph,
          child: Text(
            l10n.landingFeatureSubheading,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, color: AppColors.gray, height: 1.5),
          ),
        ),
        const SizedBox(height: 56), //[cite: 1]

        isMobile
            ? Column(
                children: features
                    .map((f) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 16), //[cite: 1]
                          child: _buildFeatureCard(f), //[cite: 1]
                        ))
                    .toList(),
              )
            : _buildFeaturesGrid(features), //[cite: 1]
      ]),
    );
  }

  Widget _buildFeaturesGrid(List<Map<String, dynamic>> features) {
    return Column(children: [
      Row(children: [
        Expanded(child: _buildFeatureCard(features[0])), //[cite: 1]
        const SizedBox(width: 20), //[cite: 1]
        Expanded(child: _buildFeatureCard(features[1])), //[cite: 1]
        const SizedBox(width: 20), //[cite: 1]
        Expanded(child: _buildFeatureCard(features[2])), //[cite: 1]
      ]),
      const SizedBox(height: 20), //[cite: 1]
      Row(children: [
        Expanded(child: _buildFeatureCard(features[3])), //[cite: 1]
        const SizedBox(width: 20), //[cite: 1]
        Expanded(child: _buildFeatureCard(features[4])), //[cite: 1]
        const SizedBox(width: 20), //[cite: 1]
        Expanded(child: _buildFeatureCard(features[5])), //[cite: 1]
      ]),
    ]);
  }

  Widget _buildFeatureCard(Map<String, dynamic> f) {
    final color = f['color'] as Color; //[cite: 1]
    return _HoverCard(
      child: Container(
        padding: const EdgeInsets.all(24), //[cite: 1]
        decoration: BoxDecoration(
          color: AppColors.white, //[cite: 1]
          borderRadius: BorderRadius.circular(18), //[cite: 1]
          border: Border.all(color: AppColors.grayLight, width: 1), //[cite: 1]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, //[cite: 1]
          children: [
            Row(children: [
              Container(
                width: 44, //[cite: 1]
                height: 44, //[cite: 1]
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), //[cite: 1]
                    borderRadius: BorderRadius.circular(12)), //[cite: 1]
                child: Icon(f['icon'] as IconData,
                    color: color, size: 22), //[cite: 1]
              ),
              const Spacer(), //[cite: 1]
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4), //[cite: 1]
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08), //[cite: 1]
                  borderRadius: BorderRadius.circular(20), //[cite: 1]
                ),
                child: Text(f['tag'] as String,
                    style: TextStyle(
                        color: color, //[cite: 1]
                        fontSize: 10, //[cite: 1]
                        fontWeight: FontWeight.w700, //[cite: 1]
                        letterSpacing: 0.5)), //[cite: 1]
              ),
            ]),
            const SizedBox(height: 18), //[cite: 1]
            TextRenderer(
              style: TextRendererStyle.header3,
              child: Text(f['title'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.charcoal,
                      letterSpacing: -0.3)),
            ),
            const SizedBox(height: 10), //[cite: 1]
            TextRenderer(
              child: Text(f['desc'] as String,
                  style: const TextStyle(
                      color: AppColors.gray, fontSize: 13, height: 1.55)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CTA SECTION ───────────────────────────────────────────────────────────
  Widget _buildCTA(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 768; //[cite: 1]
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 60, vertical: 60), //[cite: 1]
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 28 : 60,
          vertical: isMobile ? 40 : 60), //[cite: 1]
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.charcoal, Color(0xFF2d2d4e)], //[cite: 1]
          begin: Alignment.topLeft, //[cite: 1]
          end: Alignment.bottomRight, //[cite: 1]
        ),
        borderRadius: BorderRadius.circular(28), //[cite: 1]
        boxShadow: [
          BoxShadow(
              color: AppColors.charcoal.withOpacity(0.3), //[cite: 1]
              blurRadius: 40, //[cite: 1]
              offset: const Offset(0, 16)), //[cite: 1]
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              right: isMobile ? -10 : 20, //[cite: 1]
              top: -10, //[cite: 1]
              child: Opacity(
                  opacity: 0.07, //[cite: 1]
                  child: Text('🏐',
                      style: TextStyle(
                          fontSize: isMobile ? 80 : 140)))), //[cite: 1]
          Positioned(
              left: isMobile ? -10 : 20, //[cite: 1]
              bottom: -10, //[cite: 1]
              child: Opacity(
                  opacity: 0.05, //[cite: 1]
                  child: Text('🏐',
                      style: TextStyle(
                          fontSize: isMobile ? 60 : 100)))), //[cite: 1]

          Column(
            children: [
              Text(
                isMobile
                    ? l10n.landingCtaTitle.replaceFirst(' ', '\n') //[cite: 1]
                    : l10n.landingCtaTitle, //[cite: 1]
                textAlign: TextAlign.center, //[cite: 1]
                style: TextStyle(
                    fontSize: isMobile ? 26 : 38, //[cite: 1]
                    fontWeight: FontWeight.w900, //[cite: 1]
                    color: AppColors.white, //[cite: 1]
                    height: 1.15, //[cite: 1]
                    letterSpacing: -0.8), //[cite: 1]
              ),
              const SizedBox(height: 16), //[cite: 1]
              Text(
                l10n.landingCtaSubtitle,
                textAlign: TextAlign.center, //[cite: 1]
                style: const TextStyle(
                    color: AppColors.gray,
                    fontSize: 15,
                    height: 1.6), //[cite: 1]
              ),
              const SizedBox(height: 36), //[cite: 1]
              Wrap(
                spacing: 16, //[cite: 1]
                runSpacing: 12, //[cite: 1]
                alignment: WrapAlignment.center, //[cite: 1]
                children: [
                  LinkRenderer(
                    text: l10n.landingCtaStart,
                    href: '/register',
                    child: VpButton(
                      label: l10n.landingCtaStart,
                      icon: Icons.rocket_launch_rounded, //[cite: 1]
                      onPressed: () => context.push('/register'), //[cite: 1]
                    ),
                  ),
                  LinkRenderer(
                    text: l10n.loginAction,
                    href: '/login',
                    child: VpButton(
                      label: l10n.loginAction,
                      variant: VpButtonVariant.ghost, //[cite: 1]
                      onPressed: () => context.push('/login'), //[cite: 1]
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FOOTER ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final year = DateTime.now().year; //[cite: 1]
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 48), //[cite: 1]
      color: AppColors.charcoal, //[cite: 1]
      width: double.infinity, //[cite: 1]
      child: Column(children: [
        _buildLogo(), //[cite: 1]
        const SizedBox(height: 8),
        const Text(
          'Propulsez votre équipe vers les sommets.',
          style: TextStyle(color: AppColors.gray, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.go('/blog'),
              child: const Text('Blog',
                  style: TextStyle(
                      color: AppColors.gray,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            const Text('•', style: TextStyle(color: Colors.white24)),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => context.go('/privacy'),
              child: const Text('Confidentialité',
                  style: TextStyle(color: AppColors.gray, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            const Text('•', style: TextStyle(color: Colors.white24)),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => context.go('/terms'),
              child: const Text('CGU',
                  style: TextStyle(color: AppColors.gray, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 36), //[cite: 1]
        const Divider(color: Colors.white12), //[cite: 1]
        const SizedBox(height: 20), //[cite: 1]
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            //[cite: 1]
            return Column(children: [
              Text('© $year VolleyPlan. Tous droits réservés.', //[cite: 1]
                  style: const TextStyle(
                      color: AppColors.gray, fontSize: 12)), //[cite: 1]
              const SizedBox(height: 6), //[cite: 1]
              const Text(
                  'Développé avec passion pour le Volleyball 🏐', //[cite: 1]
                  style: TextStyle(
                      color: AppColors.gray, fontSize: 12)), //[cite: 1]
            ]);
          }
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, //[cite: 1]
              children: [
                Text('© $year VolleyPlan. Tous droits réservés.', //[cite: 1]
                    style: const TextStyle(
                        color: AppColors.gray, fontSize: 12)), //[cite: 1]
                const Text(
                    'Développé avec passion pour le Volleyball 🏐', //[cite: 1]
                    style: TextStyle(
                        color: AppColors.gray, fontSize: 12)), //[cite: 1]
              ]);
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. SECTION À PROPOS
// ─────────────────────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  const _AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding:
          EdgeInsets.symmetric(vertical: 80, horizontal: isMobile ? 24 : 40),
      color: AppColors.white,
      width: double.infinity,
      child: Column(
        children: [
          const Text('🏐', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          TextRenderer(
            style: TextRendererStyle.header2,
            child: Text(
              l10n.landingAboutTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isMobile ? 26 : 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal,
                  letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: TextRenderer(
              style: TextRendererStyle.paragraph,
              child: Text(
                l10n.landingAboutContent,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.gray, height: 1.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SECTION COMMENT ÇA MARCHE
// ─────────────────────────────────────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding:
          EdgeInsets.symmetric(vertical: 80, horizontal: isMobile ? 24 : 40),
      color: AppColors.offWhite,
      width: double.infinity,
      child: Column(
        children: [
          TextRenderer(
            style: TextRendererStyle.header2,
            child: Text(l10n.landingHowTitle,
                style: TextStyle(
                    fontSize: isMobile ? 26 : 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal)),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _stepCard(
                  '1', l10n.landingHowStep1Title, l10n.landingHowStep1Desc),
              _stepCard(
                  '2', l10n.landingHowStep2Title, l10n.landingHowStep2Desc),
              _stepCard(
                  '3', l10n.landingHowStep3Title, l10n.landingHowStep3Desc),
              _stepCard(
                  '4', l10n.landingHowStep4Title, l10n.landingHowStep4Desc),
              _stepCard(
                  '5', l10n.landingHowStep5Title, l10n.landingHowStep5Desc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepCard(String number, String title, String desc) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grayLight),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.yellow,
            radius: 20,
            child: Text(number,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: AppColors.charcoal)),
          ),
          const SizedBox(height: 18),
          TextRenderer(
            style: TextRendererStyle.header3,
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal)),
          ),
          const SizedBox(height: 8),
          TextRenderer(
            child: Text(desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.gray, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. POURQUOI VOLLEYPLAN (Marketing + Animation)
// ─────────────────────────────────────────────────────────────────────────────
class _WhyVolleyPlanSection extends StatefulWidget {
  const _WhyVolleyPlanSection({super.key});

  @override
  State<_WhyVolleyPlanSection> createState() => _WhyVolleyPlanSectionState();
}

class _WhyVolleyPlanSectionState extends State<_WhyVolleyPlanSection> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 768;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isVisible && mounted) setState(() => _isVisible = true);
    });

    return Container(
      padding:
          EdgeInsets.symmetric(vertical: 80, horizontal: isMobile ? 24 : 40),
      color: AppColors.charcoal,
      width: double.infinity,
      child: Column(
        children: [
          TextRenderer(
            style: TextRendererStyle.header2,
            child: Text(l10n.landingWhyTitle,
                style: TextStyle(
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white)),
          ),
          const SizedBox(height: 8),
          TextRenderer(
            child: Text(l10n.landingWhySubtitle,
                style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 56),
          isMobile
              ? Column(
                  children: [
                    Text(l10n.landingWhyCoachHeading,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 1)),
                    const SizedBox(height: 16),
                    _AnimatedBox(
                        delay: 0,
                        isVisible: _isVisible,
                        title: l10n.landingWhyCoach1Title,
                        desc: l10n.landingWhyCoach1Desc,
                        icon: Icons.timer_10_rounded),
                    const SizedBox(height: 16),
                    _AnimatedBox(
                        delay: 150,
                        isVisible: _isVisible,
                        title: l10n.landingWhyCoach2Title,
                        desc: l10n.landingWhyCoach2Desc,
                        icon: Icons.analytics_rounded),
                    const SizedBox(height: 40),
                    Text(l10n.landingWhyPlayerHeading,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 1)),
                    const SizedBox(height: 16),
                    _AnimatedBox(
                        delay: 300,
                        isVisible: _isVisible,
                        title: l10n.landingWhyPlayer1Title,
                        desc: l10n.landingWhyPlayer1Desc,
                        icon: Icons.picture_as_pdf_rounded),
                    const SizedBox(height: 16),
                    _AnimatedBox(
                        delay: 450,
                        isVisible: _isVisible,
                        title: l10n.landingWhyPlayer2Title,
                        desc: l10n.landingWhyPlayer2Desc,
                        icon: Icons.trending_up_rounded),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(l10n.landingWhyCoachHeading,
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1)),
                          const SizedBox(height: 24),
                          _AnimatedBox(
                              delay: 0,
                              isVisible: _isVisible,
                              title: l10n.landingWhyCoach1Title,
                              desc: l10n.landingWhyCoach1Desc,
                              icon: Icons.timer_10_rounded),
                          const SizedBox(height: 16),
                          _AnimatedBox(
                              delay: 150,
                              isVisible: _isVisible,
                              title: l10n.landingWhyCoach2Title,
                              desc: l10n.landingWhyCoach2Desc,
                              icon: Icons.analytics_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        children: [
                          Text(l10n.landingWhyPlayerHeading,
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1)),
                          const SizedBox(height: 24),
                          _AnimatedBox(
                              delay: 300,
                              isVisible: _isVisible,
                              title: l10n.landingWhyPlayer1Title,
                              desc: l10n.landingWhyPlayer1Desc,
                              icon: Icons.picture_as_pdf_rounded),
                          const SizedBox(height: 16),
                          _AnimatedBox(
                              delay: 450,
                              isVisible: _isVisible,
                              title: l10n.landingWhyPlayer2Title,
                              desc: l10n.landingWhyPlayer2Desc,
                              icon: Icons.trending_up_rounded),
                        ],
                      ),
                    ),
                  ],
                )
        ],
      ),
    );
  }
}

class _AnimatedBox extends StatelessWidget {
  final int delay;
  final bool isVisible;
  final String title;
  final String desc;
  final IconData icon;

  const _AnimatedBox(
      {required this.delay,
      required this.isVisible,
      required this.title,
      required this.desc,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: isVisible ? 1.0 : 0.0,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 600 + delay),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF2d2d4e),
            borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.red, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextRenderer(
                    style: TextRendererStyle.header3,
                    child: Text(title,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                  const SizedBox(height: 4),
                  TextRenderer(
                    child: Text(desc,
                        style: const TextStyle(
                            color: AppColors.gray, fontSize: 12, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. SECTION GUIDE PRATIQUE
// ─────────────────────────────────────────────────────────────────────────────
class _GuideSection extends StatelessWidget {
  const _GuideSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding:
          EdgeInsets.symmetric(vertical: 80, horizontal: isMobile ? 24 : 40),
      color: AppColors.white,
      width: double.infinity,
      child: Column(
        children: [
          TextRenderer(
            style: TextRendererStyle.header2,
            child: Text(l10n.landingGuideTitle,
                style: TextStyle(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal)),
          ),
          const SizedBox(height: 12),
          TextRenderer(
            child: Text(l10n.landingGuideSubtitle,
                style: const TextStyle(color: AppColors.gray, fontSize: 15),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 40),
          ImageRenderer(
            // TODO: Ajouter la clé 'landingGuideVideoAlt' dans les fichiers .arb
            alt: 'Vidéo de présentation de l\'application VolleyPlan',
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              height: isMobile ? 240 : 450,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.grayLight, width: 2),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        size: 72, color: AppColors.red),
                    Opacity(
                      opacity: 0.05,
                      child: Text('🏐' * 40,
                          style: const TextStyle(fontSize: 24),
                          textAlign: TextAlign.center),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. SECTION TÉMOIGNAGES
// ─────────────────────────────────────────────────────────────────────────────
class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding:
          EdgeInsets.symmetric(vertical: 80, horizontal: isMobile ? 24 : 40),
      color: AppColors.offWhite,
      width: double.infinity,
      child: Column(
        children: [
          TextRenderer(
            style: TextRendererStyle.header2,
            child: Text(l10n.landingTestimonialsTitle,
                style: TextStyle(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(
                  children: [
                    _testimonialCard(l10n.landingTestimonial1Quote,
                        l10n.landingTestimonial1Author, AppColors.red),
                    const SizedBox(height: 20),
                    _testimonialCard(l10n.landingTestimonial2Quote,
                        l10n.landingTestimonial2Author, AppColors.yellow),
                    const SizedBox(height: 20),
                    _testimonialCard(
                        l10n.landingTestimonial3Quote,
                        l10n.landingTestimonial3Author,
                        const Color(0xFF3A86FF)),
                    const SizedBox(height: 20),
                    _testimonialCard(
                        l10n.landingTestimonial4Quote,
                        l10n.landingTestimonial4Author,
                        const Color(0xFF06D6A0)),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _testimonialCard(
                                l10n.landingTestimonial1Quote,
                                l10n.landingTestimonial1Author,
                                AppColors.red)),
                        const SizedBox(width: 24),
                        Expanded(
                            child: _testimonialCard(
                                l10n.landingTestimonial2Quote,
                                l10n.landingTestimonial2Author,
                                AppColors.yellow)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: _testimonialCard(
                                l10n.landingTestimonial3Quote,
                                l10n.landingTestimonial3Author,
                                const Color(0xFF3A86FF))),
                        const SizedBox(width: 24),
                        Expanded(
                            child: _testimonialCard(
                                l10n.landingTestimonial4Quote,
                                l10n.landingTestimonial4Author,
                                const Color(0xFF06D6A0))),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _testimonialCard(String quote, String author, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppColors.charcoal.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded,
              color: color.withOpacity(0.3), size: 44),
          const SizedBox(height: 12),
          TextRenderer(
            child: Text(quote,
                style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.charcoal,
                    height: 1.6)),
          ),
          const SizedBox(height: 20),
          TextRenderer(
            child: Text(author,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. SECTION FAQ
// ─────────────────────────────────────────────────────────────────────────────
class _FAQSection extends StatelessWidget {
  const _FAQSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding:
          EdgeInsets.symmetric(vertical: 80, horizontal: isMobile ? 24 : 40),
      color: AppColors.white,
      width: double.infinity,
      child: Column(
        children: [
          TextRenderer(
            style: TextRendererStyle.header2,
            child: Text(l10n.landingFaqTitle,
                style: TextStyle(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.charcoal)),
          ),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _faqItem(l10n.landingFaq1Q, l10n.landingFaq1A),
                _faqItem(l10n.landingFaq2Q, l10n.landingFaq2A),
                _faqItem(l10n.landingFaq3Q, l10n.landingFaq3A),
                _faqItem(l10n.landingFaq4Q, l10n.landingFaq4A),
                _faqItem(l10n.landingFaq5Q, l10n.landingFaq5A),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: TextRenderer(
          style: TextRendererStyle.header3,
          child: Text(question,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                  fontSize: 15)),
        ),
        iconColor: AppColors.red,
        collapsedIconColor: AppColors.gray,
        children: [
          TextRenderer(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Text(answer,
                  style: const TextStyle(
                      color: AppColors.gray, fontSize: 14, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOVER CARD — Effet survol avec élévation d'origine
// ─────────────────────────────────────────────────────────────────────────────
class _HoverCard extends StatefulWidget {
  final Widget child;
  const _HoverCard({required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevation;
  late Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _elevation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _translate = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.012))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SlideTransition(
            position: _translate, //[cite: 1]
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18), //[cite: 1]
                boxShadow: [
                  BoxShadow(
                    color: AppColors.charcoal
                        .withOpacity(0.06 + _elevation.value * 0.1), //[cite: 1]
                    blurRadius: 8 + _elevation.value * 20, //[cite: 1]
                    offset: Offset(0, 2 + _elevation.value * 8), //[cite: 1]
                  ),
                ],
              ),
              child: widget.child, //[cite: 1]
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRID PAINTER — Grille de fond décorative d'origine
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD72638).withOpacity(0.04) //[cite: 1]
      ..strokeWidth = 1; //[cite: 1]

    const step = 48.0; //[cite: 1]
    for (double x = 0; x < size.width; x += step) {
      //[cite: 1]
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); //[cite: 1]
    }
    for (double y = 0; y < size.height; y += step) {
      //[cite: 1]
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); //[cite: 1]
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; //[cite: 1]
}
