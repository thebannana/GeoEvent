import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  bottom: BorderSide(color: colors.border),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _handleBack(context),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.card,
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.borderSoft),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'GeoEvent platform privacy and data handling overview',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: theme.brightness == Brightness.dark
                                  ? [
                                      colorScheme.primary.withValues(alpha: 0.22),
                                      colors.card,
                                    ]
                                  : [
                                      colorScheme.primary.withValues(alpha: 0.12),
                                      colors.card,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0x22000000)
                                    : const Color(0x10000000),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  'GeoEvent Legal',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'GeoEvent Privacy Policy',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'This page explains what information may be collected inside GeoEvent, how that information may be used, and what users can expect regarding privacy and access control.',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colors.textSecondary,
                                  height: 1.65,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _InfoChip(
                                    icon: Icons.update_rounded,
                                    label: 'Last updated: July 2026',
                                  ),
                                  _InfoChip(
                                    icon: Icons.shield_outlined,
                                    label: 'Platform privacy overview',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0x18000000)
                                    : const Color(0x0D000000),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: const [
                              _PolicySection(
                                number: '1',
                                title: 'Overview',
                                content:
                                    'GeoEvent is a platform for discovering, managing, and reserving events. This privacy page explains what basic user data may be collected and how it is used inside the system.',
                              ),
                              _PolicySection(
                                number: '2',
                                title: 'Information We Collect',
                                content:
                                    'GeoEvent may collect basic account and usage information such as full name, username, email address, phone number, reservation data, created events, saved events, messages, and moderation reports.',
                              ),
                              _PolicySection(
                                number: '3',
                                title: 'How Information Is Used',
                                content:
                                    'Collected data is used to support account management, event reservations, communication between users, moderation workflows, notifications, analytics, and overall platform security.',
                              ),
                              _PolicySection(
                                number: '4',
                                title: 'Sharing of Information',
                                content:
                                    'User data is not intended to be publicly shared outside the platform except where necessary for platform functionality, such as displaying organizer information, event participation details, or communication features between users.',
                              ),
                              _PolicySection(
                                number: '5',
                                title: 'Security',
                                content:
                                    'GeoEvent aims to protect user information through authenticated access, authorization rules, and controlled access to administrative features. Additional technical protection is handled by the backend and infrastructure configuration.',
                              ),
                              _PolicySection(
                                number: '6',
                                title: 'Data Retention',
                                content:
                                    'User information may be stored as long as needed for application functionality, reservation history, moderation records, reporting, and other legitimate platform operations.',
                              ),
                              _PolicySection(
                                number: '7',
                                title: 'User Rights',
                                content:
                                    'Users may request correction of inaccurate account information and may contact the platform administrator regarding questions related to their stored data.',
                              ),
                              _PolicySection(
                                number: '8',
                                title: 'Contact',
                                content:
                                    'For questions regarding privacy, data handling, or account-related issues, users should contact the GeoEvent platform administrator or support channel defined inside the application.',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.borderSoft),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This page is designed as a clear in-app privacy summary for the GeoEvent desktop workspace. Backend, database, storage, and infrastructure policies should remain aligned with the actual deployed system.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: () => _handleBack(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppThemeMetrics.radiusMd + 2,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(
                              'Back',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.number,
    required this.title,
    required this.content,
    this.isLast = false,
  });

  final String number;
  final String title;
  final String content;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
      child: Container(
        padding: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: colors.borderSoft),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                number,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                      height: 1.7,
                    ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}