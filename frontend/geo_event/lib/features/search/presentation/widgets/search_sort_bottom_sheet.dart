import 'package:flutter/material.dart';

import '../../domain/sort_option.dart';

class SearchSortBottomSheet extends StatelessWidget {
  final SortOption selected;

  const SearchSortBottomSheet({
    super.key,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161A21) : Colors.white;
    final border = isDark ? const Color(0xFF2A303A) : const Color(0xFFE3EAF3);

    Widget tile({
      required String title,
      required SortOption value,
    }) {
      final active = selected.sortBy == value.sortBy &&
          selected.sortDescending == value.sortDescending;

      return ListTile(
        onTap: () => Navigator.pop(context, value),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing:
            active ? const Icon(Icons.check_rounded, color: Color(0xFF6B8FBF)) : null,
      );
    }

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white24
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            tile(title: 'Soonest', value: SortOption.soonest),
            tile(title: 'Latest', value: SortOption.latest),
            tile(title: 'Most liked', value: SortOption.mostLiked),
            tile(title: 'Most viewed', value: SortOption.mostViewed),
            tile(title: 'Lowest price', value: SortOption.lowestPrice),
            tile(title: 'Highest price', value: SortOption.highestPrice),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}