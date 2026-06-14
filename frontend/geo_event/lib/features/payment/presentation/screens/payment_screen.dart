import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_async_view.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/glass_scaffold.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          state.selectedMethod == PaymentMethod.cash
              ? 'Confirm reservation'
              : 'Complete payment',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: SafeArea(
        child: AppAsyncView<List<EventTicketItem>>(
          value: ticketsAsync,
          loading: const AppLoadingIndicator(
            title: 'Loading payment details',
            message: 'Checking ticket availability...',
          ),
          errorBuilder: (error, _) => AppErrorState(
            title: 'Could not load ticket availability',
            message: 'Please try again.',
            onRetry: () => ref.refresh(_eventTicketsProvider(eventId).future),
          ),
          data: (tickets) {
            final matchingTickets = tickets
                .where((t) => t.ticketId == state.summary.eventTicketId)
                .toList();

            if (matchingTickets.isEmpty) {
              return const AppEmptyState(
                icon: Icons.confirmation_num_outlined,
                title: 'Selected ticket is no longer available',
                message: 'Please go back and choose another ticket.',
              );
            }

            final ticket = matchingTickets.first;

            if (!ticket.isAvailable || ticket.availableQuantity <= 0) {
              return const AppEmptyState(
                icon: Icons.confirmation_num_outlined,
                title: 'No tickets available',
                message:
                    'This event currently has no tickets available for reservation.',
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
              physics: const ClampingScrollPhysics(),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('PayPal Checkout'),
                              ),
                              body: Center(
                                child: FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
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