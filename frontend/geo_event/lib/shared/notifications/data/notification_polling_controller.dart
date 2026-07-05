import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../features/inbox/application/inbox_controller.dart';
import '../providers/inbox_providers.dart';

final notificationPollingControllerProvider =
    Provider<NotificationPollingController>((ref) {
  final controller = NotificationPollingController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class NotificationPollingController with WidgetsBindingObserver {
  NotificationPollingController(this.ref);

  final Ref ref;

  Timer? _timer;
  int? _lastUnreadCount;
  bool _isStarted = false;
  bool _isDisposed = false;
  bool _isPolling = false;

  static const Duration _pollInterval = Duration(seconds: 20);

  void start() {
    if (_isDisposed || _isStarted) return;
    _isStarted = true;
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    unawaited(pollNow(forceRefresh: true));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastUnreadCount = null;

    if (_isStarted) {
      WidgetsBinding.instance.removeObserver(this);
    }

    _isStarted = false;
  }

  Future<void> pollNow({bool forceRefresh = false}) async {
    if (_isDisposed || _isPolling) return;

    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      stop();
      return;
    }

    _isPolling = true;

    try {
      final repository = ref.read(notificationRepositoryProvider);
      final unreadCount = await repository.getUnreadCount();

      final shouldRefresh = forceRefresh ||
          _lastUnreadCount == null ||
          unreadCount != _lastUnreadCount;

      _lastUnreadCount = unreadCount;

      if (shouldRefresh) {
        await ref.read(inboxControllerProvider.notifier).refresh();
      }
    } catch (_) {
    } finally {
      _isPolling = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) {
      unawaited(pollNow());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !_isStarted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startTimer();
        unawaited(pollNow(forceRefresh: true));
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _timer?.cancel();
        _timer = null;
        break;
    }
  }

  void dispose() {
    _isDisposed = true;
    stop();
  }
}