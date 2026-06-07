import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shell/models/shell_overlay_page.dart';

class ShellUiState {
  final ShellOverlayPage? overlayPage;
  final bool isSheetOpen;
  final bool isFullScreen;
  final bool showTopBar;
  final bool showBottomBar;

  const ShellUiState({
    this.overlayPage,
    this.isSheetOpen = false,
    this.isFullScreen = false,
    this.showTopBar = true,
    this.showBottomBar = true,
  });

  bool get hasOverlay => overlayPage != null && isSheetOpen;

  ShellUiState copyWith({
    ShellOverlayPage? overlayPage,
    bool clearOverlay = false,
    bool? isSheetOpen,
    bool? isFullScreen,
    bool? showTopBar,
    bool? showBottomBar,
  }) {
    return ShellUiState(
      overlayPage: clearOverlay ? null : (overlayPage ?? this.overlayPage),
      isSheetOpen: isSheetOpen ?? this.isSheetOpen,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      showTopBar: showTopBar ?? this.showTopBar,
      showBottomBar: showBottomBar ?? this.showBottomBar,
    );
  }
}

class ShellUiController extends StateNotifier<ShellUiState> {
  ShellUiController() : super(const ShellUiState());

  void openSheet(
    ShellOverlayPage page, {
    bool fullScreen = false,
  }) {
    state = state.copyWith(
      overlayPage: page,
      isSheetOpen: true,
      isFullScreen: fullScreen,
    );
  }

  void toggleSheet(
    ShellOverlayPage page, {
    bool fullScreen = false,
  }) {
    if (state.overlayPage == page && state.isSheetOpen) {
      closeSheet();
      return;
    }

    openSheet(page, fullScreen: fullScreen);
  }

  void closeSheet() {
    state = state.copyWith(
      clearOverlay: true,
      isSheetOpen: false,
      isFullScreen: false,
    );
  }

  void setFullScreen(bool value) {
    state = state.copyWith(isFullScreen: value);
  }

  void setTopBarVisible(bool visible) {
    state = state.copyWith(showTopBar: visible);
  }

  void setBottomBarVisible(bool visible) {
    state = state.copyWith(showBottomBar: visible);
  }

  void reset() {
    state = const ShellUiState();
  }
}

final shellUiControllerProvider =
    StateNotifierProvider<ShellUiController, ShellUiState>(
  (ref) => ShellUiController(),
);