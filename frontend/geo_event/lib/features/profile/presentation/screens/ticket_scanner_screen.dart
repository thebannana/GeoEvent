import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/widgets/app_bottom_sheet_container.dart';
import '../../../../core/widgets/app_spinner.dart';
import '../../../../shared/profile/providers/profile_providers.dart';
import '../widgets/ticket_scan_result_sheet.dart';

class TicketScannerScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventTitle;

  const TicketScannerScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<TicketScannerScreen> createState() =>
      _TicketScannerScreenState();
}

class _TicketScannerScreenState extends ConsumerState<TicketScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isHandlingScan = false;
  String? _lastScannedValue;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isHandlingScan) return;

    final qrCode = capture.barcodes.first.rawValue?.trim();
    if (qrCode == null || qrCode.isEmpty) return;
    if (_lastScannedValue == qrCode) return;

    await _submitCode(qrCode);
  }

  Future<void> _submitCode(String qrCode) async {
    final trimmed = qrCode.trim();
    if (trimmed.isEmpty || _isHandlingScan) return;

    setState(() {
      _isHandlingScan = true;
      _lastScannedValue = trimmed;
    });

    try {
      final result = await ref.read(ticketScannerRepositoryProvider).validateTicket(
            eventId: widget.eventId,
            qrCode: trimmed,
          );

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TicketScanResultSheet(result: result),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isHandlingScan = false;
          _lastScannedValue = null;
        });
      }
    }
  }

  Future<void> _openManualCodeInput() async {
  final code = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ManualTicketCodeSheet(),
  );

  if (!mounted || code == null || code.trim().isEmpty) return;
  await _submitCode(code);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventTitle),
        actions: [
          IconButton(
            tooltip: 'Enter code manually',
            onPressed: _isHandlingScan ? null : _openManualCodeInput,
            icon: const Icon(Icons.keyboard_alt_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_isHandlingScan) ...[
                      const AppSpinner(size: 18, strokeWidth: 2),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        _isHandlingScan
                            ? 'Validating ticket...'
                            : 'Align the QR code inside the frame or use manual input.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ManualTicketCodeSheet extends StatefulWidget {
  const _ManualTicketCodeSheet();

  @override
  State<_ManualTicketCodeSheet> createState() => _ManualTicketCodeSheetState();
}

class _ManualTicketCodeSheetState extends State<_ManualTicketCodeSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AppBottomSheetContainer(
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter ticket code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'QR code / token',
                hintText: 'Paste or type the ticket code',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Validate code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}