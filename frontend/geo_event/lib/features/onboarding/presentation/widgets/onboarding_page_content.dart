import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.description,
    this.bullets = const [],
    required this.lottieAssetPath,
    required this.cardBackgroundColor,
    this.isActive = true,
  });

  final String title;
  final String description;
  final List<String> bullets;
  final String lottieAssetPath;
  final Color cardBackgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const textColor = Colors.black;
    final borderColor = Colors.black.withValues(alpha: 0.14);
    final innerCircleColor = Colors.white.withValues(alpha: 0.24);

    return AnimatedScale(
      duration: const Duration(milliseconds: 260),
      scale: isActive ? 1 : 0.975,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        opacity: isActive ? 1 : 0.88,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: innerCircleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Lottie.asset(
                      lottieAssetPath,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.animation_outlined,
                          size: 44,
                          color: Colors.black,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.16,
                    color: textColor,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor.withValues(alpha: 0.82),
                    height: 1.6,
                  ),
                ),
                if (bullets.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Column(
                    children: bullets
                        .map(
                          (bullet) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.black,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}