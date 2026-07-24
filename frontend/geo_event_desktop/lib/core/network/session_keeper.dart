import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../shared/auth/models/auth_state.dart';

final sessionKeeperProvider = Provider<SessionKeeper>((ref) {
  throw UnimplementedError(
    'sessionKeeperProvider must be overridden from a Consumer/WidgetRef context.',
  );
});

class SessionKeeper with WidgetsBindingObserver {
  SessionKeeper(this.ref);

  final WidgetRef ref;
  Timer? _timer;
  bool _started = false;
  bool _refreshing = false;
  ProviderSubscription<AuthState>? _authSubscription;

  void start() {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);

    _authSubscription = ref.listenManual<AuthState>(
      authStateProvider,
      (_, next) {
        _schedule(next.expiresAt, isAuthenticated: next.isAuthenticated);
      },
    );

    final state = ref.read(authStateProvider);
    _schedule(state.expiresAt, isAuthenticated: state.isAuthenticated);
  }

  void _schedule(DateTime? expiresAt, {required bool isAuthenticated}) {
    _timer?.cancel();

    if (!isAuthenticated || expiresAt == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    final expiryUtc = expiresAt.toUtc();
    final refreshAt = expiryUtc.subtract(const Duration(minutes: 2));
    final delay = refreshAt.difference(now);

    if (delay <= Duration.zero) {
      unawaited(_refreshNow());
      return;
    }

    _timer = Timer(delay, _refreshNow);
  }

  Future<void> _refreshNow() async {
    if (_refreshing) return;
    _refreshing = true;

    try {
      await ref.read(authStateProvider.notifier).refreshSession();
    } finally {
      _refreshing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated) return;

    final expiresAt = auth.expiresAt?.toUtc();
    if (expiresAt == null) return;

    final now = DateTime.now().toUtc();
    final shouldRefreshSoon =
        expiresAt.difference(now) <= const Duration(minutes: 2);

    if (shouldRefreshSoon) {
      unawaited(_refreshNow());
    } else {
      _schedule(auth.expiresAt, isAuthenticated: true);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.close();
    _timer?.cancel();
  }
}