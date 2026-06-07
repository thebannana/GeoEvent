import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/onboarding_page_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _pageCount = 3;

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
    context.go('/login');
  }

  Future<void> _nextPage() async {
    if (_currentPage >= _pageCount - 1) {
      _goToLogin();
      return;
    }

    await _pageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToLast() async {
    await _pageController.animateToPage(
      _pageCount - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                        onPressed: isLastPage ? _goToLogin : _skipToLast,
                        child: Text(isLastPage ? 'Skip' : 'Skip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: const [
                        OnboardingPageContent(
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
                        OnboardingPageContent(
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
                        OnboardingPageContent(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (index) {
                      final selected = index == _currentPage;
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
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLastPage ? _goToLogin : _nextPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isLastPage ? 'Get Started' : 'Next'),
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
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.push('/privacy'),
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