import 'package:flutter/material.dart';

import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_icon_circle_button.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import '../../../../shared/profile/utils/ticket_scanner_event_mapper.dart';
import '../../../../shared/profile/utils/ticket_scanner_formatters.dart';

class TicketScannerEventCard extends StatelessWidget {
  const TicketScannerEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final MyEventResponseDto event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = TicketScannerEventMapper.map(event);

    return AppSurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: SizedBox(
              width: 82,
              height: 96,
              child: viewModel.imageUrl != null
                  ? Image.network(
                      viewModel.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _TicketScannerImageFallback(
                          accent: viewModel.accentColor,
                          loading: true,
                        );
                      },
                      errorBuilder: (_, _, _) {
                        return _TicketScannerImageFallback(
                          accent: viewModel.accentColor,
                        );
                      },
                    )
                  : _TicketScannerImageFallback(
                      accent: viewModel.accentColor,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (viewModel.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      viewModel.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 14,
                        color: viewModel.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Scan tickets',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: viewModel.accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              TicketScannerFormatters.formatPrice(
                                viewModel.price,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppIconCircleButton(
                        tooltip: 'Open scanner',
                        onPressed: onTap,
                        icon: Icons.chevron_right_rounded,
                        size: 38,
                        foregroundColor: viewModel.accentColor,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _TicketScannerImageFallback extends StatelessWidget {
  const _TicketScannerImageFallback({
    required this.accent,
    this.loading = false,
  });

  final Color accent;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.90),
      alignment: Alignment.center,
      child: loading
          ? const AppSpinner(
              size: 22,
              strokeWidth: 2,
              color: Colors.white,
            )
          : const Icon(
              Icons.qr_code_scanner_rounded,
              size: 30,
              color: Colors.white,
            ),
    );
  }
}