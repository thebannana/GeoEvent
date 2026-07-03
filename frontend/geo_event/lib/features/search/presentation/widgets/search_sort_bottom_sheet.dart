import 'package:flutter/material.dart';

import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
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
        onTap: () => Navigator.of(context).pop(value),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
              child: Row(
                children: [
                  const Expanded(
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
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