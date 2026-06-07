import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/payment/models/payment_method.dart';
import '../../../../shared/payment/models/payment_summary.dart';
import '../../../../shared/payment/providers/payment_providers.dart';
import '../../../../shared/tickets/models/ticket_models.dart';
import '../../../../shared/tickets/providers/ticket_providers.dart';
import '../../../public_profile/application/public_profile_controller.dart';
import '../widgets/payment_amount_breakdown.dart';
import '../widgets/payment_event_info_card.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/payment_order_summary.dart';
import '../widgets/payment_quantity_selector.dart';
import '../widgets/payment_submit_section.dart';

class PaymentScreen extends ConsumerWidget {
  final int eventId;
  final int? organizerId;
  final PaymentSummary summary;

  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.summary,
    this.organizerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = paymentControllerProvider(summary);
    final state = ref.watch(provider);
    final ctrl = ref.read(provider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ticketsAsync = ref.watch(_eventTicketsProvider(eventId));
    final ownerProfileState = organizerId != null
        ? ref.watch(publicProfileControllerProvider(organizerId!))
        : null;

    final ownerDisplayName = ownerProfileState?.maybeWhen(
          data: (bundle) => bundle.user.fullName.trim().isNotEmpty
              ? bundle.user.fullName.trim()
              : null,
          orElse: () => null,
        ) ??
        summary.ownerName;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101215) : const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(
          state.selectedMethod == PaymentMethod.cash
              ? 'Confirm reservation'
              : 'Complete payment',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ticketsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load ticket availability.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          data: (tickets) {
            final matchingTickets = tickets
                .where((t) => t.ticketId == state.summary.eventTicketId)
                .toList();

            if (matchingTickets.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Selected ticket is no longer available.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final EventTicketItem ticket = matchingTickets.first;

            if (!ticket.isAvailable || ticket.availableQuantity <= 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_num_outlined,
                        size: 56,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tickets available',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This event currently has no tickets available for reservation.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final currentQuantity = state.summary.quantity > ticket.availableQuantity
                ? ticket.availableQuantity
                : state.summary.quantity;

            final effectiveSummary = state.summary.copyWith(
              quantity: currentQuantity,
              ownerName: ownerDisplayName,
            );

            if (currentQuantity != state.summary.quantity) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ctrl.setQuantity(currentQuantity);
              });
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                PaymentOrderSummary(summary: effectiveSummary),
                const SizedBox(height: 16),
                PaymentEventInfoCard(
                  ownerName: effectiveSummary.ownerName,
                  categoryName: effectiveSummary.categoryName,
                  description: effectiveSummary.eventDescription,
                ),
                const SizedBox(height: 16),
                PaymentQuantitySelector(
                  quantity: effectiveSummary.quantity,
                  maxQuantity: ticket.availableQuantity,
                  onChanged: ctrl.setQuantity,
                ),
                const SizedBox(height: 16),
                PaymentAmountBreakdown(summary: effectiveSummary),
                const SizedBox(height: 8),
                Text(
                  'Available now: ${ticket.availableQuantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                PaymentMethodSelector(
                  selected: state.selectedMethod,
                  onSelected: ctrl.selectMethod,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                PaymentSubmitSection(
                  total: effectiveSummary.total,
                  currency: effectiveSummary.currency,
                  method: state.selectedMethod,
                  loading: state.isSubmitting,
                  enabled: state.canSubmit,
                  onSubmit: () async {
                    final success = await ctrl.submit(
                      onPayPalCheckout: (amount, currency) async {
                        if (state.selectedMethod != PaymentMethod.paypal) {
                          return true;
                        }

                        // TODO: Replace this with your real PayPal screen.
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('PayPal Checkout')),
                              body: Center(
                                child: FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Mock PayPal success'),
                                ),
                              ),
                            ),
                          ),
                        );

                        return result == true;
                      },
                    );

                    if (!context.mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.selectedMethod == PaymentMethod.cash
                                ? 'Reservation confirmed successfully.'
                                : 'Payment completed successfully.',
                          ),
                        ),
                      );
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final _eventTicketsProvider =
    FutureProvider.autoDispose.family<List<EventTicketItem>, int>((ref, eventId) async {
  final repo = ref.watch(ticketsRepositoryProvider);
  return repo.getEventTickets(eventId);
});