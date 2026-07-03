import 'package:flutter/material.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/create_event_models.dart';

class CreateEventLocationSearchResultTile extends StatelessWidget {
  final MapboxPlace item;
  final VoidCallback onTap;

  const CreateEventLocationSearchResultTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if ((item.subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}