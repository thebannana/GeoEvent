import 'dart:async';

class Debouncer {
  Debouncer({
    this.delay = const Duration(milliseconds: 400),
  });

  final Duration delay;
  Timer? _timer;

  bool get isActive => _timer?.isActive ?? false;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  Future<void> runAsync(Future<void> Function() action) async {
    _timer?.cancel();

    final completer = Completer<void>();
    _timer = Timer(delay, () async {
      try {
        await action();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (e, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(e, stackTrace);
        }
      }
    });

    return completer.future;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}