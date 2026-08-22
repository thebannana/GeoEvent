import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
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

    Future.microtask(() {
      if (!mounted) return;
      ref.read(reservationsControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
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
              error: (error, stackTrace) => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  sliver: SliverToBoxAdapter(
                    child: AppErrorState(
                      title: 'Failed to load reservations',
                      message: ErrorMapper.toMessage(
                        error,
                        stackTrace: stackTrace,
                        fallbackMessage: 'Pull to refresh or try again.',
                      ),
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
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Cancel reservation?',
      message: 'Reservation for '
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
      _showMessage('Reservation cancelled.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to cancel reservation.',
        tag: 'ReservationsScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not cancel. Please try again.',
        ),
      );
    }
  }

  Future<void> _requestRefund(
    BuildContext context,
    Reservation reservation,
  ) async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => _RefundRequestDialog(
        reservation: reservation,
      ),
    );

    if (reason == null || !mounted) return;

    try {
      await ref.read(reservationsControllerProvider.notifier).requestRefund(
            reservation.reservationId,
            reason: reason.isEmpty ? null : reason,
          );

      if (!mounted) return;
      _showMessage('Refund request submitted.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to request refund.',
        tag: 'ReservationsScreen',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not submit refund request. Please try again.',
        ),
      );
    }
  }
}

class _RefundRequestDialog extends StatefulWidget {
  final Reservation reservation;

  const _RefundRequestDialog({
    required this.reservation,
  });

  @override
  State<_RefundRequestDialog> createState() => _RefundRequestDialogState();
}

class _RefundRequestDialogState extends State<_RefundRequestDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  void _submit() {
    Navigator.of(context).pop(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;

    return AlertDialog(
      title: const Text('Request refund?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reservation for '
            '${reservation.quantity} ticket'
            '${reservation.quantity > 1 ? 's' : ''} '
            'will be submitted for admin review.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Explain why you want a refund',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Send request'),
        ),
      ],
    );
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