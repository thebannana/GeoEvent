import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/layout/app_scaffold.dart';
import '../widgets/onboarding_page_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _loginRoute = '/login';
  static const String _privacyRoute = '/privacy';
  static const String _registerRoute = '/register';
  static const Duration _pageAnimationDuration = Duration(milliseconds: 420);
  static const Duration _autoSlideInterval = Duration(seconds: 5);
  static const String _logoAssetPath = 'assets/images/geoevent.png';

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Discover events around you',
      description:
          'Explore what is happening nearby with a live event map built for quick discovery.',
      bullets: [
        'Find concerts, gatherings, food spots, and community moments.',
        'See events visually on the map instead of digging through long lists.',
        'Open details fast and decide what is worth your time.',
      ],
      lottieAssetPath: 'assets/lotties/Globe.json',
      cardBackgroundColor: Color(0xFFF2C94C), // yellow
    ),
    _OnboardingPageData(
      title: 'Connect, reserve, and plan',
      description:
          'Keep your social plans in one place with reservations, reminders, and event updates.',
      bullets: [
        'Reserve spots before they fill up.',
        'Track updates and changes without losing the thread.',
        'Use notifications to stay on top of your plans.',
      ],
      lottieAssetPath: 'assets/lotties/Chat.json',
      cardBackgroundColor: Color(0xFFEB5757), // red
    ),
    _OnboardingPageData(
      title: 'Your event flow, simplified',
      description:
          'GeoEvent helps you move from discovery to attendance with less friction and better context.',
      bullets: [
        'Search faster with personalized results.',
        'Manage tickets, reservations, and notifications in one app.',
        'Jump in now and start exploring your city.',
      ],
      lottieAssetPath: 'assets/lotties/Walk.json',
      cardBackgroundColor: Color(0xFF2F80ED), // blue
    ),
  ];

  int get _pageCount => _pages.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(_autoSlideInterval, (_) async {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _pageCount;
      await _goToPage(nextPage);
    });
  }

  void _resetAutoSlide() {
    _autoSlideTimer?.cancel();
    _startAutoSlide();
  }

  void _goToLogin() {
    context.push(_loginRoute);
  }

  void _goToRegister() {
    context.push(_registerRoute);
  }

  void _openPrivacyPolicy() {
    context.push(_privacyRoute);
  }

  Future<void> _goToPage(int pageIndex) async {
    if (!_pageController.hasClients) return;

    await _pageController.animateToPage(
      pageIndex,
      duration: _pageAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? scheme.surface : scheme.surfaceContainerLowest;
    final strokeColor = scheme.outline.withValues(alpha: isDark ? 0.22 : 0.14);

    return AppScaffold(
      child: Container(
        color: backgroundColor,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 165,
                          height: 30,
                          child: Image.asset(
                            _logoAssetPath,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (_, _, _) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 24,
                                  color: scheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _openPrivacyPolicy,
                          child: Text(
                            'Privacy',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          height: 620,
                          child: GestureDetector(
                            onPanDown: (_) => _resetAutoSlide(),
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: _onPageChanged,
                              itemCount: _pageCount,
                              itemBuilder: (context, index) {
                                final item = _pages[index];
                                final isActive = index == _currentPage;

                                return AnimatedPadding(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOut,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: isActive ? 6 : 20,
                                  ),
                                  child: OnboardingPageContent(
                                    title: item.title,
                                    description: item.description,
                                    bullets: item.bullets,
                                    lottieAssetPath: item.lottieAssetPath,
                                    cardBackgroundColor: item.cardBackgroundColor,
                                    isActive: isActive,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _OnboardingPageIndicator(
                      pageCount: _pageCount,
                      currentPage: _currentPage,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _goToLogin,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: strokeColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Sign in'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _goToRegister,
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Sign up'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageIndicator extends StatelessWidget {
  const _OnboardingPageIndicator({
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final selected = index == currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final List<String> bullets;
  final String lottieAssetPath;
  final Color cardBackgroundColor;

  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.bullets,
    required this.lottieAssetPath,
    required this.cardBackgroundColor,
  });
}