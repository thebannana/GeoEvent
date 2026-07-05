import 'package:flutter/material.dart';

import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../shared/public_profile/models/public_profile_event_filter.dart';

class PublicProfileEventFilters extends StatelessWidget {
  final PublicProfileEventFilter selected;
  final ValueChanged<PublicProfileEventFilter> onChanged;
  final bool isBusy;

  const PublicProfileEventFilters({
    super.key,
    required this.selected,
    required this.onChanged,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        children: [
          _chip('All', PublicProfileEventFilter.all),
          _chip('Upcoming', PublicProfileEventFilter.upcoming),
          _chip('Past', PublicProfileEventFilter.past),
          _chip('Free', PublicProfileEventFilter.free),
          _chip('Paid', PublicProfileEventFilter.paid),
        ],
      ),
    );
  }

  Widget _chip(String label, PublicProfileEventFilter value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppChip(
        label: label,
        selected: selected == value,
        onTap: isBusy ? null : () => onChanged(value),
      ),
    );
  }
}