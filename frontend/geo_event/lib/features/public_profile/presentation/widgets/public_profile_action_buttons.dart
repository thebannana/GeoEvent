import 'package:flutter/material.dart';

import '../../../../shared/public_profile/models/public_profile_user.dart';

class PublicProfileActionButtons extends StatelessWidget {
  final PublicProfileUser user;
  final VoidCallback onMessageTap;
  final VoidCallback onReportTap;

  const PublicProfileActionButtons({
    super.key,
    required this.user,
    required this.onMessageTap,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onMessageTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Message'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReportTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Report'),
            ),
          ),
        ],
      ),
    );
  }
}