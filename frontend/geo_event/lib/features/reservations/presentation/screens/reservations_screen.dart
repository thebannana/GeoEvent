import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reservations_controller.dart';
import '../../../../shared/reservations/models/reservation.dart';
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
    _ReservationFilter(label: 'Pending', value: 'Pending'),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: ctrl.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: ctrl.setSearch,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search reservations',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ctrl.setSearch('');
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
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
                        _FilterChip(
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
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              )
            else if (state.paged.hasError)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: _ErrorState(onRetry: ctrl.load),
                ),
              )
            else if (filteredReservations.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverToBoxAdapter(
                  child: _EmptyState(
                    filter: state.activeStatus,
                    hasSearch: state.searchQuery.trim().isNotEmpty,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.6)
                : isDark
                    ? const Color(0xFF2A303A)
                    : const Color(0xFFE3EAF3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? primary
                : isDark
                    ? Colors.white70
                    : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? filter;
  final bool hasSearch;

  const _EmptyState({
    this.filter,
    required this.hasSearch,
  });

  @override
  Widget build(BuildContext context) {
    final title = hasSearch
        ? 'No matching reservations'
        : filter == null
            ? 'No reservations yet'
            : 'No matching results';

    final subtitle = hasSearch
        ? 'Try a different search term.'
        : filter == null
            ? 'Reserved events and tickets will appear here.'
            : 'No ${filter!.toLowerCase()} reservations found.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF17191D)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A303A)
              : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.confirmation_num_outlined,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF17191D)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A303A)
              : const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load reservations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull to refresh or try again.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}