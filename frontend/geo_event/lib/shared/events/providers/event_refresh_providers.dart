import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventMapRefreshProvider = StateProvider<int>((ref) => 0);

void triggerEventMapRefresh(WidgetRef ref) {
  ref.read(eventMapRefreshProvider.notifier).state++;
}