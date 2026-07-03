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

  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.public_rounded,
      title: 'Discover events around you',
      description:
          'Explore what is happening nearby with a live event map built for quick discovery.',
      bullets: [
        'Find concerts, gatherings, food spots, and community moments.',
        'See events visually on the map instead of digging through long lists.',
        'Open details fast and decide what is worth your time.',
      ],
    ),
    _OnboardingPageData(
      icon: Icons.people_alt_rounded,
      title: 'Connect, reserve, and plan',
      description:
          'Keep your social plans in one place with reservations, reminders, and event updates.',
      bullets: [
        'Reserve spots before they fill up.',
        'Track updates and changes without losing the thread.',
        'Use notifications to stay on top of your plans.',
      ],
    ),
    _OnboardingPageData(
      icon: Icons.route_rounded,
      title: 'Your event flow, simplified',
      description:
          'GeoEvent helps you move from discovery to attendance with less friction and better context.',
      bullets: [
        'Search faster with personalized results.',
        'Manage tickets, reservations, and notifications in one app.',
        'Jump in now and start exploring your city.',
      ],
    ),
  ];

  int get _pageCount => _pages.length;
  bool get _isLastPage => _currentPage == _pageCount - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    context.go(_loginRoute);
  }

  void _openPrivacyPolicy() {
    context.push(_privacyRoute);
  }

  Future<void> _goToPage(int pageIndex) async {
    if (!_pageController.hasClients) return;

    await _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _nextPage() async {
    if (_isLastPage) {
      _goToLogin();
      return;
    }

    await _goToPage(_currentPage + 1);
  }

  Future<void> _skipToLast() async {
    if (_isLastPage) {
      _goToLogin();
      return;
    }

    await _goToPage(_pageCount - 1);
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

    return AppScaffold(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'GeoEvent',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _skipToLast,
                        child: Text(_isLastPage ? 'Continue' : 'Skip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pageCount,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return OnboardingPageContent(
                          icon: page.icon,
                          title: page.title,
                          description: page.description,
                          bullets: page.bullets,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _OnboardingPageIndicator(
                    pageCount: _pageCount,
                    currentPage: _currentPage,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLastPage ? _goToLogin : _nextPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isLastPage ? 'Get Started' : 'Next'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _goToLogin,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Skip for now'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _openPrivacyPolicy,
                    child: const Text('Privacy Policy'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;

  const _OnboardingPageIndicator({
    required this.pageCount,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final selected = index == currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
  });
}