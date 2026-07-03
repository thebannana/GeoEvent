import 'package:flutter/material.dart';

import '../../../../shared/reports/models/report_reason.dart';

class ReportReasonSelector extends StatelessWidget {
  final ReportReason? selected;
  final ValueChanged<ReportReason> onSelected;

  const ReportReasonSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: ReportReason.values.map((reason) {
        final isSelected = selected == reason;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelected(reason),
              child: Ink(
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.16)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.55)
                        : colorScheme.outline.withValues(alpha: 0.75),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        reason.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      size: 20,
                      color: isSelected
                          ? colorScheme.primary
                          : theme.iconTheme.color?.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}