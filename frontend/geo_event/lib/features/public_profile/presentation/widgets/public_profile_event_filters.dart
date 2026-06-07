import 'package:flutter/material.dart';
import '../screens/public_profile_screen.dart';

class PublicProfileEventFilters extends StatelessWidget {
  final PublicProfileEventFilter selected;
  final ValueChanged<PublicProfileEventFilter> onChanged;

  const PublicProfileEventFilters({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        children: [
          _chip(context, 'All', PublicProfileEventFilter.all),
          _chip(context, 'Upcoming', PublicProfileEventFilter.upcoming),
          _chip(context, 'Past', PublicProfileEventFilter.past),
          _chip(context, 'Free', PublicProfileEventFilter.free),
          _chip(context, 'Paid', PublicProfileEventFilter.paid),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, PublicProfileEventFilter value) {
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onChanged(value),
      ),
    );
  }
}