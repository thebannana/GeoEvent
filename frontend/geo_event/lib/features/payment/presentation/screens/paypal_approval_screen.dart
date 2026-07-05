import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/payment/data/paypal_return_coordinator.dart';
import '../../../../shared/profile/models/paypal_approval_result.dart';

class PayPalApprovalScreen extends ConsumerStatefulWidget {
  const PayPalApprovalScreen({
    super.key,
    required this.approveUrl,
    required this.expectedOrderId,
    required this.reservationId,
  });

  final String approveUrl;
  final String expectedOrderId;
  final int reservationId;

  @override
  ConsumerState<PayPalApprovalScreen> createState() =>
      _PayPalApprovalScreenState();
}

class _PayPalApprovalScreenState extends ConsumerState<PayPalApprovalScreen>
    with WidgetsBindingObserver {
  bool _opening = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkCoordinatorResult();
      await _openPayPal();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCoordinatorResult();
    }
  }

  Future<void> _openPayPal() async {
    if (_opening || !mounted) return;

    setState(() {
      _opening = true;
    });

    try {
      final uri = Uri.parse(widget.approveUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  void _checkCoordinatorResult() {
    if (_completed || !mounted) return;

    final result = ref
        .read(payPalReturnCoordinatorProvider.notifier)
        .takeForReservation(widget.reservationId);

    if (result == null) return;

    _completed = true;

    if (result.approved) {
      Navigator.of(context).pop(
        PayPalApprovalResult.approved(
          orderId: result.orderId ?? widget.expectedOrderId,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      PayPalApprovalResult.cancelled(
        'PayPal payment was cancelled.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PayPalReturnCoordinatorState>(
      payPalReturnCoordinatorProvider,
      (_, _) {
        _checkCoordinatorResult();
      },
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('PayPal Checkout'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Continue with PayPal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A PayPal approval page will open outside the app. After approval or cancellation, you will be returned to the app automatically.',
            ),
            const SizedBox(height: 16),
            SelectableText(widget.approveUrl),
            const SizedBox(height: 8),
            SelectableText('Order ID: ${widget.expectedOrderId}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _opening ? null : _openPayPal,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(_opening ? 'Opening PayPal...' : 'Open PayPal'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(
                    PayPalApprovalResult.cancelled(
                      'PayPal payment was cancelled.',
                    ),
                  );
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}