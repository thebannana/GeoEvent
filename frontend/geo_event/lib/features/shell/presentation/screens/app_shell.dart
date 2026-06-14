import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_icon_circle_button.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../shared/location/models/map_filter_selection.dart';
import '../../../../shared/shell/models/shell_overlay_page.dart';
import '../../../../shared/shell/models/shell_tab.dart';
import '../../../../shared/shell/providers/shell_overlay_providers.dart';
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
import '../../application/shell_controller.dart';
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

  final GlobalKey<MapHomeScreenState> _mapKey = GlobalKey<MapHomeScreenState>();

  bool _isFullScreen = false;
  bool _showFilter = false;
  bool _showDrawer = false;
  bool _hasActiveNavigation = false;

  double _sheetExtent = _midSheetSize;
  double _mapBearing = 0.0;

  MapFilterSelection _mapFilterSelection = MapFilterSelection.defaults();

  double _baseMinExtentFor(
    ShellOverlayPage? overlayPage,
    ShellTab? selectedTab,
  ) {
    if (overlayPage == ShellOverlayPage.search) {
      return _searchMinSheetSize;
    }
    return _baseMinSheetSize;
  }

  double _effectiveMinExtent(
    BuildContext context,
    ShellOverlayPage? overlayPage,
    ShellTab? selectedTab,
  ) {
    final baseMin = _baseMinExtentFor(overlayPage, selectedTab);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    if (keyboardInset <= 0) return baseMin;

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

  void _resetTransientUi({
    bool keepFilter = false,
    bool keepDrawer = false,
  }) {
    if (!mounted) return;

    setState(() {
      _isFullScreen = false;
      _sheetExtent = _midSheetSize;
      if (!keepFilter) _showFilter = false;
      if (!keepDrawer) _showDrawer = false;
    });
  }

  void _setSheetExtent(
    double extent, {
    required double minExtent,
  }) {
    if (!mounted) return;

    final clamped = extent.clamp(minExtent, _maxSheetSize);
    setState(() {
      _sheetExtent = clamped;
      _isFullScreen = clamped >= _fullScreenTrigger;
    });
  }

  void _handleTabTap(ShellTab tab) {
    final current = ref.read(shellControllerProvider);

    if (current == tab) {
      _closeSheet();
      return;
    }

    ref.read(shellOverlayPageProvider.notifier).state = null;
    _resetTransientUi();
    ref.read(shellControllerProvider.notifier).openTab(tab);
  }

  void _closeSheet() {
    ref.read(shellControllerProvider.notifier).close();
    ref.read(shellOverlayPageProvider.notifier).state = null;
    _resetTransientUi();
  }

  void _closeSearchOverlayOnly() {
    ref.read(shellOverlayPageProvider.notifier).state = null;
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
    ref.read(shellControllerProvider.notifier).close();
    ref.read(shellOverlayPageProvider.notifier).state = ShellOverlayPage.search;
    _resetTransientUi();
  }

  void _openDrawer() {
    ref.read(shellControllerProvider.notifier).close();
    ref.read(shellOverlayPageProvider.notifier).state = null;

    if (!mounted) return;

    setState(() {
      _showDrawer = true;
      _showFilter = false;
      _isFullScreen = false;
      _sheetExtent = _midSheetSize;
    });
  }

  void _toggleFilter() {
    ref.read(shellOverlayPageProvider.notifier).state = null;

    if (!mounted) return;

    setState(() {
      _showFilter = !_showFilter;
      _showDrawer = false;
      _isFullScreen = false;
    });
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

  String _titleForTab(ShellTab tab) {
    switch (tab) {
      case ShellTab.chat:
        return 'Chat';
      case ShellTab.reservations:
        return 'My Reservations';
      case ShellTab.createEvent:
        return 'Create Event';
      case ShellTab.inbox:
        return 'Inbox';
      case ShellTab.profile:
        return 'My Profile';
    }
  }

  Widget _bodyForTab(ShellTab tab) {
    switch (tab) {
      case ShellTab.chat:
        return const ChatScreen();
      case ShellTab.reservations:
        return const ReservationsScreen();
      case ShellTab.createEvent:
        return const CreateEventScreen();
      case ShellTab.inbox:
        return const InboxScreen();
      case ShellTab.profile:
        return const ProfileTabPage();
    }
  }

  Future<void> _openEventDetails(int eventId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          eventId: eventId,
          onCloseParentSearchSheet: _closeSearchOverlayOnly,
        ),
      ),
    );
  }

  void _handleSheetDragUpdate(
    DragUpdateDetails details,
    double availableHeight,
    double minExtent,
  ) {
    final delta = details.primaryDelta ?? 0;
    final fractionDelta = delta / availableHeight;
    _setSheetExtent(
      _sheetExtent - fractionDelta,
      minExtent: minExtent,
    );
  }

  void _handleSheetDragEnd(
    DragEndDetails details,
    ShellOverlayPage? overlayPage,
    double minExtent,
  ) {
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
        if (overlayPage != null) {
          _closeSearchOverlayOnly();
        } else {
          _closeSheet();
        }
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

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(shellControllerProvider);
    final overlayPage = ref.watch(shellOverlayPageProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final minSheetExtent = _effectiveMinExtent(
      context,
      overlayPage,
      selectedTab,
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

    final hasSheetPage = selectedTab != null || overlayPage != null;
    final anyOverlay = _showFilter || _showDrawer || overlayPage != null;

    final showTopBar =
        !_showDrawer &&
        !_isFullScreen &&
        overlayPage == null &&
        selectedTab == null;

    return GlassScaffold(
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
                onCloseSearchOverlay: _closeSearchOverlayOnly,
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
                      tooltip: 'Open filters',
                      onPressed: _toggleFilter,
                    ),
                  ),
                ),
              ),
            if (!anyOverlay && !_isFullScreen && selectedTab == null)
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
                  ignoring: _isFullScreen,
                  child: GestureDetector(
                    onTap: overlayPage != null
                        ? _closeSearchOverlayOnly
                        : _closeSheet,
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: _isFullScreen ? 0.05 : 0.14,
                      ),
                    ),
                  ),
                ),
              ),
            if (hasSheetPage)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: screenHeight * _sheetExtent,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Builder(
                      builder: (context) {
                        final String title;
                        final Widget body;

                        if (overlayPage == ShellOverlayPage.search) {
                          title = 'Search';
                          body = SearchSheet(
                            onCloseSheet: _closeSearchOverlayOnly,
                          );
                        } else {
                          final tab = selectedTab!;
                          title = _titleForTab(tab);
                          body = _bodyForTab(tab);
                        }

                        return ShellSheetContent(
                          title: title,
                          onClose: overlayPage != null
                              ? _closeSearchOverlayOnly
                              : _closeSheet,
                          onDragUpdate: (details) => _handleSheetDragUpdate(
                            details,
                            screenHeight,
                            minSheetExtent,
                          ),
                          onDragEnd: (details) => _handleSheetDragEnd(
                            details,
                            overlayPage,
                            minSheetExtent,
                          ),
                          body: body,
                          isFullScreen: _isFullScreen,
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _isFullScreen ? 0.0 : 1.0,
          child: IgnorePointer(
            ignoring: _isFullScreen,
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