import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shell/models/shell_tab.dart';

class ShellController extends StateNotifier<ShellTab?> {
  ShellController() : super(null);

  void openTab(ShellTab tab) {
    state = state == tab ? null : tab;
  }

  void close() {
    state = null;
  }

  bool isOpen(ShellTab tab) => state == tab;
}

final shellControllerProvider =
    StateNotifierProvider<ShellController, ShellTab?>(
  (ref) => ShellController(),
);