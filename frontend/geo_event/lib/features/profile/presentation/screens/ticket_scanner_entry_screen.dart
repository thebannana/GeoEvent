import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_icon_circle_button.dart';
import '../../../../core/widgets/app_spinner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../shared/events/models/my_event_response_dto.dart';
import '../../application/my_events_controller.dart';
import 'ticket_scanner_screen.dart';

class TicketScannerEntryScreen extends ConsumerWidget {
  const TicketScannerEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEventsAsync = ref.watch(myEventsProvider);

    Future<void> onRefresh() async {
      await ref.read(myEventsProvider.notifier).refresh();
    }

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Ticket scanner'),
        backgroundColor: Colors.transparent,
      ),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: myEventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No managed events',
                    message: 'You do not manage any events.',
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 14, bottom: 20),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];

                return TicketScannerEventCard(
                  event: event,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TicketScannerScreen(
                          eventId: event.eventId,
                          eventTitle: event.title,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 220),
              Center(child: AppSpinner(size: 28, strokeWidth: 2.6)),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              AppErrorState(
                title: 'Failed to load events',
                message: error.toString(),
                onRetry: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketScannerEventCard extends StatelessWidget {
  final MyEventResponseDto event;
  final VoidCallback onTap;

  const TicketScannerEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  Color _segmentColor() {
    final source =
        (event.segmentName ?? event.genreName ?? event.subGenreName ?? '')
            .toLowerCase();

    if (source.contains('concert') || source.contains('music')) {
      return const Color(0xFF5E7BFF);
    }
    if (source.contains('sport')) {
      return const Color(0xFFFF5A76);
    }
    if (source.contains('education') || source.contains('seminar')) {
      return const Color(0xFF68C95A);
    }
    return const Color(0xFF6B8FBF);
  }

  String _formatPrice(num? price) {
    if (price == null || price <= 0) return 'Free';
    if (price % 1 == 0) return '${price.toInt()}\$';
    return '${price.toStringAsFixed(2)}\$';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _segmentColor();

    final subtitleParts = [
      if ((event.segmentName ?? '').isNotEmpty) event.segmentName!,
      if ((event.genreName ?? '').isNotEmpty) event.genreName!,
    ];
    final subtitle = subtitleParts.join(' · ');

    final imageUrl = event.coverImageUrl ??
        ((event.imageUrls.isNotEmpty) ? event.imageUrls.first : null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: AppSurfaceCard(
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
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _TicketScannerImageFallback(
                            accent: accent,
                            loading: true,
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return _TicketScannerImageFallback(accent: accent);
                        },
                      )
                    : _TicketScannerImageFallback(accent: accent),
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
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
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
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scan tickets',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accent,
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
                                _formatPrice(event.price),
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
                          foregroundColor: accent,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _TicketScannerImageFallback extends StatelessWidget {
  final Color accent;
  final bool loading;

  const _TicketScannerImageFallback({
    required this.accent,
    this.loading = false,
  });

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