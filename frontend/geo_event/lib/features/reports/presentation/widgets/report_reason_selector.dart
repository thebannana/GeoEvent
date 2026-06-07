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
    return Column(
      children: ReportReason.values.map((reason) {
        final isSelected = selected == reason;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(reason),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.16)
                    : Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1C1F24)
                        : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.55)
                      : Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2D323A)
                          : const Color(0xFFE6EBF2),
                ),
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
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .iconTheme
                            .color
                            ?.withValues(alpha: 0.75),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}