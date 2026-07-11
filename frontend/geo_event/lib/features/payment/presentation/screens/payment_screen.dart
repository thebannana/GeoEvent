import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/async/app_async_view.dart';
import '../../../../core/widgets/feedback/app_confirm_dialog.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/payment/models/payment_method.dart';
import '../../../../shared/payment/models/payment_summary.dart';
import '../../../../shared/payment/providers/payment_providers.dart';
import '../../../../shared/profile/models/paypal_approval_result.dart';
import '../../../../shared/tickets/models/ticket_models.dart';
import '../../../../shared/tickets/providers/ticket_providers.dart';
import '../../../public_profile/application/public_profile_controller.dart';
import '../widgets/payment_amount_breakdown.dart';
import '../widgets/payment_event_info_card.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/payment_order_summary.dart';
import '../widgets/payment_quantity_selector.dart';
import '../widgets/payment_submit_section.dart';
import 'payment_success_screen.dart';
import 'paypal_approval_screen.dart';

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

  static const double _bamToEurRate = 0.51129;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ticketsAsync = ref.watch(eventTicketsProvider(eventId));
    final provider = paymentControllerProvider(summary);
    final state = ref.watch(provider);
    final ctrl = ref.read(provider.notifier);

    final ownerProfileState = organizerId != null
        ? ref.watch(publicProfileControllerProvider(organizerId!))
        : null;

    final ownerDisplayName = ownerProfileState?.maybeWhen(
          data: (bundle) {
            final fullName = bundle.user.fullName.trim();
            return fullName.isNotEmpty ? fullName : null;
          },
          orElse: () => null,
        ) ??
        summary.ownerName;

    final initialSummary = summary.copyWith(ownerName: ownerDisplayName);
    final initialIsFree = initialSummary.isFree;

    return AppScaffold(
      appBar: AppBar(
        title: Text(initialIsFree ? 'Confirm reservation' : 'Complete payment'),
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
          errorBuilder: (context, error) => AppErrorState(
            title: 'Could not load ticket availability',
            message: ErrorMapper.toMessage(
              error,
              fallbackMessage: 'Please try again.',
            ),
            onRetry: () => ref.refresh(eventTicketsProvider(eventId).future),
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

            final currentQuantity =
                state.summary.quantity > ticket.availableQuantity
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

            final isFree = effectiveSummary.isFree;
            final paypalChargedAmount = _paypalChargedAmount(effectiveSummary);
            final paypalChargedCurrency = _paypalChargedCurrency(
              effectiveSummary.currency,
            );

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
                  isFree
                      ? 'No payment is required for this ticket.'
                      : 'Available now: ${ticket.availableQuantity}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isFree) ...[
                  const SizedBox(height: 16),
                  PaymentMethodSelector(
                    selected: state.selectedMethod,
                    onSelected: ctrl.selectMethod,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.selectedMethod == PaymentMethod.paypal
                        ? _paypalHelperText(
                            originalAmount: effectiveSummary.total,
                            originalCurrency: effectiveSummary.currency,
                            paypalAmount: paypalChargedAmount,
                            paypalCurrency: paypalChargedCurrency,
                          )
                        : 'Cash reservations are confirmed without PayPal and handled offline.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Text(
                    'This is a free reservation. No payment step is needed.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                  method: isFree ? PaymentMethod.cash : state.selectedMethod,
                  loading: state.isSubmitting,
                  enabled:
                      state.canSubmit &&
                      currentQuantity <= ticket.availableQuantity,
                  isFree: isFree,
                  onSubmit: () async {
                    final selectedMethod =
                        isFree ? PaymentMethod.cash : state.selectedMethod;

                    final confirmed = await showSubmitConfirmationDialog(
                      context,
                      method: selectedMethod,
                      total: effectiveSummary.total,
                      currency: effectiveSummary.currency,
                      isFree: isFree,
                      paypalAmount: paypalChargedAmount,
                      paypalCurrency: paypalChargedCurrency,
                    );

                    if (!confirmed || !context.mounted) return;

                    try {
                      final success = await ctrl.submit(
                        onPayPalApproval: ({
                          required approveUrl,
                          required orderId,
                          required reservationId,
                        }) async {
                          if (isFree) {
                            return PayPalApprovalResult.cancelled(
                              'No PayPal approval is needed for free reservations.',
                            );
                          }

                          if (selectedMethod != PaymentMethod.paypal) {
                            return PayPalApprovalResult.cancelled(
                              'PayPal is not the selected payment method.',
                            );
                          }

                          final result = await Navigator.of(context)
                              .push<PayPalApprovalResult>(
                            MaterialPageRoute(
                              builder: (_) => PayPalApprovalScreen(
                                approveUrl: approveUrl,
                                expectedOrderId: orderId,
                                reservationId: reservationId,
                              ),
                            ),
                          );

                          return result ??
                              PayPalApprovalResult.cancelled(
                                'PayPal payment was cancelled.',
                              );
                        },
                      );

                      if (!context.mounted) return;

                      if (success) {
                        final successTitle = isFree
                            ? 'Reservation confirmed'
                            : selectedMethod == PaymentMethod.paypal
                                ? 'Payment successful'
                                : 'Cash reservation confirmed';

                        final successMessage = isFree
                            ? 'Your free reservation has been confirmed successfully.'
                            : selectedMethod == PaymentMethod.paypal
                                ? 'Your PayPal payment was completed successfully and your reservation is now confirmed.'
                                : 'Your cash reservation has been confirmed successfully.';

                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => PaymentSuccessScreen(
                              title: successTitle,
                              message: successMessage,
                            ),
                          ),
                        );

                        if (!context.mounted) return;

                        if (result == true) {
                          Navigator.of(context).pop(true);
                        }
                      }
                    } catch (error, stackTrace) {
                      AppLogger.error(
                        'Payment submission failed.',
                        tag: 'PaymentScreen',
                        error: error,
                        stackTrace: stackTrace,
                      );

                      final message = ErrorMapper.toMessage(
                        error,
                        stackTrace: stackTrace,
                        fallbackMessage:
                            'Unable to complete your reservation right now.',
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
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

  Future<bool> showSubmitConfirmationDialog(
    BuildContext context, {
    required PaymentMethod method,
    required double total,
    required String currency,
    required bool isFree,
    required double paypalAmount,
    required String paypalCurrency,
  }) {
    final actionLabel = isFree
        ? 'Confirm reservation'
        : (method == PaymentMethod.paypal
            ? 'Proceed to PayPal'
            : 'Confirm cash reservation');

    final message = isFree
        ? 'You are about to confirm this free reservation.'
        : method == PaymentMethod.paypal
            ? _paypalDialogMessage(
                total: total,
                currency: currency,
                paypalAmount: paypalAmount,
                paypalCurrency: paypalCurrency,
              )
            : 'You are about to confirm this reservation with cash payment for ${_formatPrice(total, currency)}.';

    return AppConfirmDialog.show(
      context,
      title: actionLabel,
      message: message,
      confirmLabel: actionLabel,
    );
  }

  static String _formatPrice(double amount, String currency) {
    return PriceFormatter.format(
      amount,
      currency: currency.trim().toUpperCase(),
      decimalDigits: 2,
      fallback: '-',
    );
  }

  static String _paypalChargedCurrency(String originalCurrency) {
    if (originalCurrency.trim().toUpperCase() == 'BAM') {
      return 'EUR';
    }
    return originalCurrency.trim().toUpperCase();
  }

  static double _paypalChargedAmount(PaymentSummary summary) {
    if (summary.currency.trim().toUpperCase() == 'BAM') {
      return double.parse(
        (summary.total * _bamToEurRate).toStringAsFixed(2),
      );
    }
    return double.parse(summary.total.toStringAsFixed(2));
  }

  static String _paypalHelperText({
    required double originalAmount,
    required String originalCurrency,
    required double paypalAmount,
    required String paypalCurrency,
  }) {
    final normalizedOriginalCurrency = originalCurrency.trim().toUpperCase();

    if (normalizedOriginalCurrency == paypalCurrency) {
      return 'You will be redirected to PayPal for approval.';
    }

    return 'You will be redirected to PayPal for approval. This ticket is priced in ${_formatPrice(originalAmount, normalizedOriginalCurrency)}, and PayPal will charge approximately ${_formatPrice(paypalAmount, paypalCurrency)}.';
  }

  static String _paypalDialogMessage({
    required double total,
    required String currency,
    required double paypalAmount,
    required String paypalCurrency,
  }) {
    final normalizedCurrency = currency.trim().toUpperCase();

    if (normalizedCurrency == paypalCurrency) {
      return 'You are about to continue to PayPal for a payment of ${_formatPrice(total, normalizedCurrency)}.';
    }

    return 'You are about to continue to PayPal. The reservation total is ${_formatPrice(total, normalizedCurrency)}, and PayPal will charge approximately ${_formatPrice(paypalAmount, paypalCurrency)}.';
  }
}