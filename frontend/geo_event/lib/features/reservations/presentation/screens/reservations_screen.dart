import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/inputs/app_chip.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/reservations/models/reservation.dart';
import '../../../../shared/reservations/models/reservation_status.dart';
import '../../application/reservations_controller.dart';
import '../widgets/reservation_card.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() =>
      _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  final _scrollController = ScrollController();

  static const _filters = <_ReservationFilter>[
    _ReservationFilter(label: 'All', value: null),
    _ReservationFilter(label: 'Pending', value: ReservationStatus.pending),
    _ReservationFilter(label: 'Confirmed', value: ReservationStatus.confirmed),
    _ReservationFilter(label: 'Cancelled', value: ReservationStatus.cancelled),
    _ReservationFilter(label: 'Expired', value: ReservationStatus.expired),
    _ReservationFilter(label: 'Refunded', value: ReservationStatus.refunded),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

void _onScroll() {
  if (!_scrollController.hasClients) return;
  final position = _scrollController.position;
  if (position.pixels >= position.maxScrollExtent - 240) {
    final state = ref.read(reservationsControllerProvider).valueOrNull;
    if (state?.isFetchingMore == true) return;
    ref.read(reservationsControllerProvider.notifier).loadMore();
  }
}

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(reservationsControllerProvider);
    final ctrl = ref.read(reservationsControllerProvider.notifier);

    return AppScaffold(
      backgroundColor: Colors.transparent,
      child: RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: asyncState.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (data) => Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _filters.length; i++) ...[
                          AppChip(
                            label: _filters[i].label,
                            selected: data.statusFilter == _filters[i].value,
                            onTap: () =>
                                ctrl.setStatusFilter(_filters[i].value),
                          ),
                          if (i != _filters.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ...asyncState.when(
              loading: () => [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
                  sliver: SliverToBoxAdapter(
                    child: AppLoadingIndicator(
                      title: 'Loading reservations',
                      message: 'Please wait while we prepare your bookings.',
                      centered: false,
                    ),
                  ),
                ),
              ],
              error: (_, _) => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  sliver: SliverToBoxAdapter(
                    child: AppErrorState(
                      title: 'Failed to load reservations',
                      message: 'Pull to refresh or try again.',
                      onRetry: ctrl.refresh,
                    ),
                  ),
                ),
              ],
              data: (data) {
                if (data.items.isEmpty) {
                  return [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      sliver: SliverToBoxAdapter(
                        child: AppEmptyState(
                          icon: Icons.confirmation_num_outlined,
                          title: data.statusFilter == null
                              ? 'No reservations yet'
                              : 'No matching results',
                          message: data.statusFilter == null
                              ? 'Reserved events and tickets will appear here.'
                              : 'No ${data.statusFilter!.apiValue.toLowerCase()} reservations found.',
                        ),
                      ),
                    ),
                  ];
                }

                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    sliver: SliverList.separated(
                      itemCount: data.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final reservation = data.items[index];
                        return ReservationCard(
                          reservation: reservation,
                          onCancel: reservation.canBeCancelled
                              ? () => _confirmCancel(context, reservation)
                              : null,
                          onRefund: reservation.canRequestRefund
                              ? () => _requestRefund(context, reservation)
                              : null,
                        );
                      },
                    ),
                  ),
                  if (data.isFetchingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Center(
                          child: AppSpinner(size: 22, strokeWidth: 2),
                        ),
                      ),
                    ),
                ];
              },
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    Reservation reservation,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Cancel reservation?',
      message: 'Reservation #${reservation.reservationId} for '
          '${reservation.quantity} ticket${reservation.quantity > 1 ? 's' : ''} '
          'will be cancelled.',
      cancelLabel: 'Keep',
      confirmLabel: 'Cancel reservation',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(reservationsControllerProvider.notifier)
          .cancelReservation(reservation.reservationId);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Reservation cancelled.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not cancel. Please try again.'),
        ),
      );
    }
  }

  Future<void> _requestRefund(
  BuildContext context,
  Reservation reservation,
) async {
  final reasonController = TextEditingController();

  try {
    final reason = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request refund?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reservation #${reservation.reservationId} for '
              '${reservation.quantity} ticket${reservation.quantity > 1 ? 's' : ''} '
              'will be submitted for admin review.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Explain why you want a refund',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Send request'),
          ),
        ],
      ),
    );

    if (reason == null || !mounted) return;

    await ref.read(reservationsControllerProvider.notifier).requestRefund(
          reservation.reservationId,
          reason: reason.isEmpty ? null : reason,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refund request submitted.'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not submit refund request. Please try again.'),
      ),
    );
  } finally {
    reasonController.dispose();
  }
}
}

class _ReservationFilter {
  final String label;
  final ReservationStatus? value;

  const _ReservationFilter({
    required this.label,
    required this.value,
  });
}