import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bottom_sheet_container.dart';
import '../../domain/sort_option.dart';

class SearchSortBottomSheet extends StatelessWidget {
  final SortOption selected;

  const SearchSortBottomSheet({
    super.key,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile(SortOption value) {
      final active = selected.sortBy == value.sortBy &&
          selected.sortDescending == value.sortDescending;

      return ListTile(
        onTap: () => Navigator.pop(context, value),
        contentPadding: EdgeInsets.zero,
        title: Text(
          value.label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: active
            ? Icon(
                Icons.check_rounded,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      );
    }

    return AppBottomSheetContainer(
  scrollable: false,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
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
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: SortOption.all.map(tile).toList(),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}