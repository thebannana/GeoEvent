import 'package:flutter/material.dart';

import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'May 29, 2026';

  static const String _introText =
      'This privacy policy explains the main categories of data GeoEvent may process, why that data is used, and the basic choices available to you when using the application.';

  static const List<String> _dataCollectionItems = [
    'Account details such as your name, email address, and login information.',
    'Event activity such as reservations, tickets, favorites, and notifications.',
    'Approximate or precise location data when you enable location-based discovery.',
    'Basic device and diagnostic information such as crash logs and app performance data.',
  ];

  static const List<String> _dataUsageItems = [
    'To help you discover nearby events and personalized recommendations.',
    'To manage reservations, tickets, reminders, and event updates.',
    'To improve app stability, security, and performance.',
    'To communicate essential account or event-related information.',
  ];

  static const List<String> _permissionItems = [
    'Location: used to show relevant events near you and to improve map-based discovery and routing.',
    'Notifications: used to send reservation updates, reminders, and important event activity.',
    'Camera and media access: used only when you upload profile photos or event media.',
  ];

  static const List<String> _recommendationItems = [
    'GeoEvent uses a recommendation system that considers your saved interests, past activity, and basic popularity signals.',
    'Recommendation data is used only to improve your experience in the app and is not sold to third parties.',
  ];

  static const List<String> _paymentItems = [
    'GeoEvent supports online payments through PayPal for certain reservations.',
    'Cash payments are handled directly between you and the event organizer, and any issues or disputes related to cash are the organizer’s responsibility.',
    'Refunds processed through the app are limited to PayPal payments and are based on the actual amount charged via PayPal.',
  ];

  static const List<String> _userChoiceItems = [
    'You can choose whether to grant device permissions such as location, notifications, or camera access.',
    'You can stop using location-based features by disabling location access in your device system settings.',
    'You can disable push notifications in your device settings.',
    'You may request account or personal data deletion according to the final published policy used by the project.',
  ];

  static const String _dataProtectionText =
      'GeoEvent does not sell your personal information. Data is collected only to provide and improve the service, personalize event discovery, and keep your reservations and tickets in sync with your activity.';

  static const String _thirdPartyText =
      'GeoEvent may rely on third-party services such as PayPal for payments, Mapbox for maps, and analytics or crash reporting providers. These services will be listed in the final published policy used for production builds, along with links to their own privacy terms.';

  static const String _contactText =
      'For privacy-related questions, personal data requests, or account concerns, use the official support or legal contact email provided by the project (kundodenis@gmail.com).';

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
            title: 'Recommendation system',
            child: _BulletList(items: _recommendationItems),
          ),
          const _SectionBlock(
            title: 'Payments and refunds',
            child: _BulletList(items: _paymentItems),
          ),
          const _SectionBlock(
            title: 'Your choices',
            child: _BulletList(items: _userChoiceItems),
          ),
          _SectionBlock(
            title: 'Data protection',
            child: Text(
              _dataProtectionText,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
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