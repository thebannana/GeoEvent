import 'package:flutter/material.dart';

import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/glass_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassScaffold(
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
            'Last updated: May 29, 2026',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          AppSurfaceCard(
            child: Text(
              'This screen is a product-ready placeholder for GeoEvent. Replace it with your final legal text before release, but keep the same structure so users can clearly understand what data the app uses and why.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          _SectionBlock(
            title: 'What GeoEvent may collect',
            child: const _BulletList(
              items: [
                'Account details such as your name, email address, and login information.',
                'Event activity such as reservations, tickets, favorites, and notifications.',
                'Approximate or precise location data if location-based discovery is enabled.',
                'Basic device and diagnostic information such as crash logs and app performance data.',
              ],
            ),
          ),
          _SectionBlock(
            title: 'How data may be used',
            child: const _BulletList(
              items: [
                'To help you discover nearby events and relevant recommendations.',
                'To manage reservations, tickets, reminders, and event updates.',
                'To improve app stability, security, and performance.',
                'To communicate essential account or event-related information.',
              ],
            ),
          ),
          _SectionBlock(
            title: 'Permissions',
            child: const _BulletList(
              items: [
                'Location: used to show relevant events near you and improve map-based discovery.',
                'Notifications: used to send reservation updates, reminders, and important event activity.',
                'Camera or media access: only needed if profile photos, event media, or uploads are supported.',
              ],
            ),
          ),
          _SectionBlock(
            title: 'Your choices',
            child: const _BulletList(
              items: [
                'You can choose whether to grant certain device permissions.',
                'You can stop using location-based features by disabling location access in system settings.',
                'You can disable push notifications in your device settings.',
                'You may request account or personal data deletion according to the final published policy.',
              ],
            ),
          ),
          _SectionBlock(
            title: 'Third-party services',
            child: Text(
              'GeoEvent may rely on third-party services for authentication, payments, analytics, maps, notifications, or crash reporting. The final version of this policy should identify those services clearly before public release.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          _SectionBlock(
            title: 'Contact',
            child: Text(
              'For privacy-related questions, data requests, or account concerns, add your official support or legal contact email here.',
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