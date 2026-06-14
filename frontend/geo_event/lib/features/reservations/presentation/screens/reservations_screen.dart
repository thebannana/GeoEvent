import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../shared/reservations/models/reservation.dart';
import '../../../search/presentation/widgets/search_bar.dart';
import '../../application/reservations_controller.dart';
import '../widgets/reservation_card.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() =>
      _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  final _searchController = TextEditingController();

  static const _filters = <_ReservationFilter>[
    _ReservationFilter(label: 'All', value: null),
    _ReservationFilter(label: 'Confirmed', value: 'Confirmed'),
    _ReservationFilter(label: 'Cancelled', value: 'Cancelled'),
    _ReservationFilter(label: 'Expired', value: 'Expired'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationsControllerProvider);
    final ctrl = ref.read(reservationsControllerProvider.notifier);

    final filteredReservations = state.filteredItems;

    if (_searchController.text != state.searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
        composing: TextRange.empty,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: ctrl.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: SearchBarWidget(
                  controller: _searchController,
                  onChanged: ctrl.setSearch,
                  onClear: () {
                    _searchController.clear();
                    ctrl.setSearch('');
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < _filters.length; i++) ...[
                        AppChip(
                          label: _filters[i].label,
                          selected: state.activeStatus == _filters[i].value,
                          onTap: () => ctrl.setFilter(_filters[i].value),
                        ),
                        if (i != _filters.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (state.paged.isLoading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: AppLoadingIndicator(
                    title: 'Loading reservations',
                    message: 'Please wait while we prepare your bookings.',
                    centered: false,
                  ),
                ),
              )
            else if (state.paged.hasError)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: AppErrorState(
                    title: 'Failed to load reservations',
                    message: 'Pull to refresh or try again.',
                    onRetry: ctrl.load,
                  ),
                ),
              )
            else if (filteredReservations.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: Icons.confirmation_num_outlined,
                    title: state.searchQuery.trim().isNotEmpty
                        ? 'No matching reservations'
                        : state.activeStatus == null
                            ? 'No reservations yet'
                            : 'No matching results',
                    message: state.searchQuery.trim().isNotEmpty
                        ? 'Try a different search term.'
                        : state.activeStatus == null
                            ? 'Reserved events and tickets will appear here.'
                            : 'No ${state.activeStatus!.toLowerCase()} reservations found.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverList.separated(
                  itemCount: filteredReservations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final reservation = filteredReservations[index];
                    return ReservationCard(
                      reservation: reservation,
                      onCancel: () => _confirmCancel(
                        context,
                        reservation,
                      ),
                    );
                  },
                ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: Text(
          'Reservation #${reservation.reservationId} for '
          '${reservation.quantity} ticket${reservation.quantity > 1 ? 's' : ''} '
          'will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel reservation'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(reservationsControllerProvider.notifier)
        .cancel(reservation.reservationId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Reservation cancelled.'
              : 'Could not cancel. Please try again.',
        ),
      ),
    );
  }
}

class _ReservationFilter {
  final String label;
  final String? value;

  const _ReservationFilter({
    required this.label,
    required this.value,
  });
}