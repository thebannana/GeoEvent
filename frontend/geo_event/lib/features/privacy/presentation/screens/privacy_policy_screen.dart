import 'package:flutter/material.dart';

import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'May 29, 2026';

  static const List<String> _dataCollectionItems = [
    'Account details such as your name, email address, and login information.',
    'Event activity such as reservations, tickets, favorites, and notifications.',
    'Approximate or precise location data if location-based discovery is enabled.',
    'Basic device and diagnostic information such as crash logs and app performance data.',
  ];

  static const List<String> _dataUsageItems = [
    'To help you discover nearby events and relevant recommendations.',
    'To manage reservations, tickets, reminders, and event updates.',
    'To improve app stability, security, and performance.',
    'To communicate essential account or event-related information.',
  ];

  static const List<String> _permissionItems = [
    'Location: used to show relevant events near you and improve map-based discovery.',
    'Notifications: used to send reservation updates, reminders, and important event activity.',
    'Camera or media access: only needed if profile photos, event media, or uploads are supported.',
  ];

  static const List<String> _userChoiceItems = [
    'You can choose whether to grant certain device permissions.',
    'You can stop using location-based features by disabling location access in system settings.',
    'You can disable push notifications in your device settings.',
    'You may request account or personal data deletion according to the final published policy.',
  ];

  static const String _introText =
      'This privacy policy explains the main categories of data GeoEvent may process, the reasons for processing, and the basic choices available to users when using the application.';

  static const String _thirdPartyText =
      'GeoEvent may rely on third-party services for authentication, payments, analytics, maps, notifications, or crash reporting. Those services should be clearly identified in the final published policy used for release builds.';

  static const String _contactText =
      'For privacy-related questions, personal data requests, or account concerns, provide the official support or legal contact email used by the project.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'GeoEvent Privacy Policy',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Last updated: $_lastUpdated',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          AppSurfaceCard(
            child: Text(
              _introText,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionBlock(
            title: 'What GeoEvent may collect',
            child: _BulletList(items: _dataCollectionItems),
          ),
          const _SectionBlock(
            title: 'How data may be used',
            child: _BulletList(items: _dataUsageItems),
          ),
          const _SectionBlock(
            title: 'Permissions',
            child: _BulletList(items: _permissionItems),
          ),
          const _SectionBlock(
            title: 'Your choices',
            child: _BulletList(items: _userChoiceItems),
          ),
          _SectionBlock(
            title: 'Third-party services',
            child: Text(
              _thirdPartyText,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          _SectionBlock(
            title: 'Contact',
            child: Text(
              _contactText,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionBlock({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;

  const _BulletList({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}