import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
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

class _TicketScannerScreenState extends ConsumerState<TicketScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _isHandlingScan = false;
  String? _lastScannedValue;
  DateTime? _lastScanAt;
  bool _didValidateTicket = false;

  static const Duration _duplicateCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;

    if (state == AppLifecycleState.resumed && !_isHandlingScan) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.stop();
    }
  }

  bool _shouldIgnoreDuplicate(String value) {
    final lastValue = _lastScannedValue;
    final lastAt = _lastScanAt;

    if (lastValue == null || lastAt == null) return false;
    if (lastValue != value) return false;

    return DateTime.now().toUtc().difference(lastAt) < _duplicateCooldown;
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isHandlingScan || capture.barcodes.isEmpty) return;

    final qrCode = capture.barcodes.first.rawValue?.trim();
    if (qrCode == null || qrCode.isEmpty) return;
    if (_shouldIgnoreDuplicate(qrCode)) return;

    await _submitCode(qrCode);
  }

  Future<void> _submitCode(String qrCode) async {
  final trimmed = qrCode.trim();

  if (trimmed.isEmpty ||
      _isHandlingScan ||
      _shouldIgnoreDuplicate(trimmed)) {
    return;
  }

  setState(() {
    _isHandlingScan = true;
    _lastScannedValue = trimmed;
    _lastScanAt = DateTime.now().toUtc();
  });

  try {
    await _controller.stop();

    final result =
        await ref.read(ticketScannerRepositoryProvider).validateTicket(
              eventId: widget.eventId,
              qrCode: trimmed,
            );

    if (!mounted) return;

    _didValidateTicket = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketScanResultSheet(result: result),
    );
  } catch (error, stackTrace) {
    AppLogger.error(
      'Ticket validation failed.',
      tag: 'TicketScannerScreen',
      error: error,
      stackTrace: stackTrace,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toMessage(
              error,
              stackTrace: stackTrace,
              fallbackMessage: 'Ticket validation failed. Please try again.',
            ),
          ),
        ),
      );
  } finally {
    if (mounted) {
      await _controller.start();

      setState(() {
        _isHandlingScan = false;
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
    return AppScaffold(
    appBar: AppBar(
      leading: BackButton(
        onPressed: () {
          Navigator.of(context).pop(_didValidateTicket);
        },
      ),
      title: Text(widget.eventTitle),
      actions: [
        IconButton(
          tooltip: _isHandlingScan
              ? 'Manual entry is unavailable while validation is in progress'
              : 'Enter code manually',
          onPressed:
              _isHandlingScan ? null : _openManualCodeInput,
          icon: const Icon(Icons.keyboard_alt_rounded),
        ),
      ],
    ),
      child: Stack(
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
    WidgetsBinding.instance.removeObserver(this);
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
  final _formKey = GlobalKey<FormState>();

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
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AppBottomSheetContainer(
        scrollable: false,
        child: Form(
          key: _formKey,
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
              TextFormField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'QR code / token',
                  hintText: 'Paste or type the ticket code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Enter a ticket code to continue.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
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
      ),
    );
  }
}