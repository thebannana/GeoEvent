import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/inputs/app_icon_circle_button.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../shared/auth/models/auth_state.dart';
import '../../../../shared/location/models/map_filter_selection.dart';
import '../../../../shared/shell/models/shell_overlay_page.dart';
import '../../../../shared/shell/models/shell_tab.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/shell_controller.dart';
import '../../application/shell_ui_controller.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../create_event/presentation/screens/create_event_screen.dart';
import '../../../event/presentation/screens/event_detail_screen.dart';
import '../../../inbox/presentation/screens/inbox_screen.dart';
import '../../../map/presentation/screens/map_home_screen.dart';
import '../../../map/presentation/widgets/map_filter_panel.dart';
import '../../../map/presentation/widgets/map_settings_drawer.dart';
import '../../../profile/presentation/screens/profile_tab_page.dart';
import '../../../reservations/presentation/screens/reservations_screen.dart';
import '../../../search/presentation/screens/search_sheet.dart';
import '../widgets/shell_bottom_nav_bar.dart';
import '../widgets/shell_compass_button.dart';
import '../widgets/shell_sheet_content.dart';
import '../widgets/shell_top_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const double _baseMinSheetSize = 0.22;
  static const double _searchMinSheetSize = 0.42;
  static const double _midSheetSize = 0.52;
  static const double _upperSheetSize = 0.78;
  static const double _maxSheetSize = 1.0;
  static const double _fullScreenTrigger = 0.90;
  static const double _liveCloseThreshold = 0.30;

  static const String _searchTitle = 'Search';
  static const String _chatTitle = 'Chat';
  static const String _reservationsTitle = 'My Reservations';
  static const String _createEventTitle = 'Create Event';
  static const String _inboxTitle = 'Inbox';
  static const String _profileTitle = 'My Profile';
  static const String _openFiltersTooltip = 'Open filters';
  static const String _eventCreatedMessage = 'Event created successfully.';

  final GlobalKey<MapHomeScreenState> _mapKey = GlobalKey<MapHomeScreenState>();

  bool _showFilter = false;
  bool _showDrawer = false;
  bool _hasActiveNavigation = false;

  double _sheetExtent = _midSheetSize;
  double _mapBearing = 0.0;

  MapFilterSelection _mapFilterSelection = MapFilterSelection.defaults();

  ProviderSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription = ref.listenManual<AuthState>(
      authStateProvider,
      (previous, next) {
        final wasAuthenticated = previous?.isAuthenticated ?? false;
        final isAuthenticated = next.isAuthenticated;

        if (wasAuthenticated != isAuthenticated) {
          _resetMapFilters();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  ShellController get _shellController =>
      ref.read(shellControllerProvider.notifier);

  ShellUiController get _shellUiController =>
      ref.read(shellUiControllerProvider.notifier);

  double _baseMinExtentFor(ShellOverlayPage? overlayPage) {
    if (overlayPage == ShellOverlayPage.search) {
      return _searchMinSheetSize;
    }

    return _baseMinSheetSize;
  }

  double _effectiveMinExtent(
    BuildContext context,
    ShellOverlayPage? overlayPage,
  ) {
    final baseMin = _baseMinExtentFor(overlayPage);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    if (keyboardInset <= 0) {
      return baseMin;
    }

    final keyboardFraction = keyboardInset / screenHeight;

    if (overlayPage == ShellOverlayPage.search) {
      return (baseMin + keyboardFraction + 0.06).clamp(
        _searchMinSheetSize,
        _maxSheetSize,
      );
    }

    return (baseMin + keyboardFraction).clamp(
      _baseMinSheetSize,
      _maxSheetSize,
    );
  }

  void _setFullScreen(bool value) {
    _shellUiController.setFullScreen(value);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _resetTransientUi({
    bool keepFilter = false,
    bool keepDrawer = false,
  }) {
    if (!mounted) return;

    setState(() {
      _sheetExtent = _midSheetSize;
      if (!keepFilter) {
        _showFilter = false;
      }
      if (!keepDrawer) {
        _showDrawer = false;
      }
    });

    _setFullScreen(false);
  }

  void _setSheetExtent(
    double extent, {
    required double minExtent,
  }) {
    if (!mounted) return;

    final clampedExtent = extent.clamp(minExtent, _maxSheetSize);
    final isFullScreen = clampedExtent >= _fullScreenTrigger;

    setState(() {
      _sheetExtent = clampedExtent;
    });

    _setFullScreen(isFullScreen);
  }

  void _dismissCurrentSheet(ShellOverlayPage? overlayPage) {
    if (overlayPage != null) {
      _closeOverlayOnly();
    } else {
      _closeSheet();
    }
  }

  void _handleTabTap(ShellTab tab) {
    final currentTab = ref.read(shellControllerProvider);

    _shellUiController.closeSheet();

    if (currentTab == tab) {
      _shellController.close();
      _resetTransientUi();
      return;
    }

    _resetTransientUi();
    _shellController.openTab(tab);
  }

  void _closeSheet() {
    _shellController.close();
    _shellUiController.closeSheet();
    _resetTransientUi();
  }

  void _closeOverlayOnly() {
    _shellUiController.closeSheet();
    _resetTransientUi();
  }

  void _closeDrawer() {
    if (!_showDrawer || !mounted) return;

    setState(() {
      _showDrawer = false;
    });
  }

  void _closeFilter() {
    if (!_showFilter || !mounted) return;

    setState(() {
      _showFilter = false;
    });
  }

  void _openSearchSheet() {
    _shellController.close();
    _shellUiController.openSheet(ShellOverlayPage.search);
    _resetTransientUi();
  }

  void _openDrawer() {
    _shellController.close();
    _shellUiController.closeSheet();

    if (!mounted) return;

    setState(() {
      _showDrawer = true;
      _showFilter = false;
      _sheetExtent = _midSheetSize;
    });

    _setFullScreen(false);
  }

  void _toggleFilter() {
    _shellUiController.closeSheet();

    if (!mounted) return;

    setState(() {
      _showFilter = !_showFilter;
      _showDrawer = false;
    });

    _setFullScreen(false);
  }

  void _handleBearingChanged(double bearing) {
    if (!mounted) return;

    setState(() {
      _mapBearing = bearing;
    });
  }

  void _handleNavigationUiVisibilityChanged(bool hasActiveNavigation) {
    if (!mounted) return;

    setState(() {
      _hasActiveNavigation = hasActiveNavigation;
    });
  }

  Future<void> _handleEventCreated(CreateEventSuccessResult result) async {
    _closeSheet();

    if (!mounted) return;

    _showMessage(_eventCreatedMessage);

    try {
      await _mapKey.currentState?.reloadMapPins(forceResync: true);
      await _mapKey.currentState?.focusOnEventLocation(
        latitude: result.latitude,
        longitude: result.longitude,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to refresh map after event creation.',
        tag: 'AppShell',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Event was created, but map refresh failed.',
        ),
      );
    }
  }

  String _titleForTab(ShellTab tab) {
    switch (tab) {
      case ShellTab.chat:
        return _chatTitle;
      case ShellTab.reservations:
        return _reservationsTitle;
      case ShellTab.createEvent:
        return _createEventTitle;
      case ShellTab.inbox:
        return _inboxTitle;
      case ShellTab.profile:
        return _profileTitle;
    }
  }

  Widget _bodyForTab(ShellTab tab) {
    switch (tab) {
      case ShellTab.chat:
        return const ChatScreen();
      case ShellTab.reservations:
        return const ReservationsScreen();
      case ShellTab.createEvent:
        return CreateEventScreen(
          onCreated: _handleEventCreated,
        );
      case ShellTab.inbox:
        return const InboxScreen();
      case ShellTab.profile:
        return ProfileTabPage(
          onClose: _closeSheet,
        );
    }
  }

  ({String title, Widget body}) _resolveSheetPage(
    ShellOverlayPage? overlayPage,
    ShellTab? selectedTab,
  ) {
    if (overlayPage == ShellOverlayPage.search) {
      return (
        title: _searchTitle,
        body: SearchSheet(
          onCloseSheet: _closeOverlayOnly,
        ),
      );
    }

    final tab = selectedTab!;
    return (
      title: _titleForTab(tab),
      body: _bodyForTab(tab),
    );
  }

  Future<void> _openEventDetails(int eventId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          eventId: eventId,
          onCloseParentSearchSheet: _closeOverlayOnly,
        ),
      ),
    );
  }

  void _handleSheetDragUpdate(
    DragUpdateDetails details,
    double availableHeight,
    double minExtent,
    ShellOverlayPage? overlayPage,
  ) {
    final delta = details.primaryDelta ?? 0;
    final fractionDelta = delta / availableHeight;
    final nextExtent = _sheetExtent - fractionDelta;

    if (nextExtent <= _liveCloseThreshold) {
      _dismissCurrentSheet(overlayPage);
      return;
    }

    final clampedExtent = nextExtent.clamp(minExtent, _maxSheetSize);
    final isFullScreen = clampedExtent >= _fullScreenTrigger;

    setState(() {
      _sheetExtent = clampedExtent;
    });

    _setFullScreen(isFullScreen);
  }

  void _handleSheetDragEnd(
    DragEndDetails details,
    ShellOverlayPage? overlayPage,
    double minExtent,
  ) {
    if (_sheetExtent <= _liveCloseThreshold) {
      _dismissCurrentSheet(overlayPage);
      return;
    }

    final velocity = details.primaryVelocity ?? 0;

    final targets = <double>[
      minExtent,
      if (_midSheetSize > minExtent) _midSheetSize,
      if (_upperSheetSize > minExtent) _upperSheetSize,
      _maxSheetSize,
    ];

    double target = targets.first;
    double bestDistance = (_sheetExtent - target).abs();

    for (final candidate in targets.skip(1)) {
      final distance = (_sheetExtent - candidate).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        target = candidate;
      }
    }

    if (velocity > 700) {
      if (_sheetExtent <= minExtent + 0.03) {
        _dismissCurrentSheet(overlayPage);
        return;
      }
      target = minExtent;
    } else if (velocity < -700) {
      target = _maxSheetSize;
    }

    _setSheetExtent(
      target,
      minExtent: minExtent,
    );
  }

  void _resetMapFilters() {
    if (!mounted) return;
    setState(() {
      _mapFilterSelection = MapFilterSelection.defaults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(shellControllerProvider);
    final shellUiState = ref.watch(shellUiControllerProvider);
    final overlayPage = shellUiState.overlayPage;
    final isFullScreen = shellUiState.isFullScreen;

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final minSheetExtent = _effectiveMinExtent(
      context,
      overlayPage,
    );

    if (_sheetExtent < minSheetExtent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _setSheetExtent(
          minSheetExtent,
          minExtent: minSheetExtent,
        );
      });
    }

    final hasSheetPage = selectedTab != null || shellUiState.hasOverlay;
    final hasAnyOverlay = _showFilter || _showDrawer || shellUiState.hasOverlay;

    final showTopBar = !_showDrawer &&
        !isFullScreen &&
        !shellUiState.hasOverlay &&
        selectedTab == null;

    final sheetPage = hasSheetPage
        ? _resolveSheetPage(overlayPage, selectedTab)
        : null;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: MapHomeScreen(
                key: _mapKey,
                filterSelection: _mapFilterSelection,
                onBearingChanged: _handleBearingChanged,
                onEventSelected: _openEventDetails,
                onCloseSearchOverlay: _closeOverlayOnly,
                onNavigationUiVisibilityChanged:
                    _handleNavigationUiVisibilityChanged,
              ),
            ),
            if (_showDrawer)
              Positioned.fill(
                child: MapSettingsDrawer(
                  onClose: _closeDrawer,
                ),
              ),
            if (_showFilter)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeFilter,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: MapFilterPanel(
                          initialSelection: _mapFilterSelection,
                          onClose: _closeFilter,
                          onApply: (selection) {
                            if (!mounted) return;

                            setState(() {
                              _mapFilterSelection = selection;
                              _showFilter = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (showTopBar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ShellTopBar(
                  showAll: !_showDrawer && !_showFilter,
                  onMenu: _openDrawer,
                  onSearch: _openSearchSheet,
                  onFilter: _toggleFilter,
                  onDirections: _hasActiveNavigation
                      ? () => _mapKey.currentState?.openActiveNavigationUi()
                      : null,
                  showDirectionsButton: _hasActiveNavigation,
                ),
              ),
            if (_showDrawer)
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 16, 0),
                    child: AppIconCircleButton(
                      icon: Icons.tune_rounded,
                      tooltip: _openFiltersTooltip,
                      onPressed: _toggleFilter,
                    ),
                  ),
                ),
              ),
            if (!hasAnyOverlay && !isFullScreen && selectedTab == null)
              Positioned(
                right: 16,
                bottom: 140,
                child: ShellCompassButton(
                  bearing: _mapBearing,
                  onTap: () => _mapKey.currentState?.centerOnUserPuck(),
                ),
              ),
            if (hasSheetPage)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: isFullScreen,
                  child: GestureDetector(
                    onTap: shellUiState.hasOverlay
                        ? _closeOverlayOnly
                        : _closeSheet,
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: isFullScreen ? 0.05 : 0.14,
                      ),
                    ),
                  ),
                ),
              ),
            if (hasSheetPage && sheetPage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: screenHeight * _sheetExtent,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ShellSheetContent(
                      title: sheetPage.title,
                      onClose: shellUiState.hasOverlay
                          ? _closeOverlayOnly
                          : _closeSheet,
                      onDragUpdate: (details) => _handleSheetDragUpdate(
                        details,
                        screenHeight,
                        minSheetExtent,
                        overlayPage,
                      ),
                      onDragEnd: (details) => _handleSheetDragEnd(
                        details,
                        overlayPage,
                        minSheetExtent,
                      ),
                      body: sheetPage.body,
                      isFullScreen: isFullScreen,
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isFullScreen ? 0.0 : 1.0,
          child: IgnorePointer(
            ignoring: isFullScreen,
            child: ShellBottomNavBar(
              selectedTab: selectedTab,
              onTap: _handleTabTap,
            ),
          ),
        ),
      ),
    );
  }
}