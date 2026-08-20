import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/admin_profile/models/admin_search_catalog.dart';
import '../../../../shared/admin_profile/models/admin_search_result.dart';
import '../../../../shared/admin_profile/providers/admin_categories_providers.dart';
import '../../../../shared/admin_profile/providers/admin_events_providers.dart';
import '../../../../shared/admin_profile/providers/admin_users_providers.dart';
import '../../../../shared/map/providers/mapbox_providers.dart';
import '../../../../shared/shell/models/admin_shell_models.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../auth/presentation/screens/edit_profile_screen.dart';
import '../../application/profile_controller.dart';
import '../widgets/admin_categories_panel.dart';
import '../widgets/admin_dashboard_panel.dart';
import '../widgets/admin_events_panel.dart';
import '../widgets/admin_navbar.dart';
import '../widgets/admin_reports_panel.dart';
import '../widgets/admin_settings_panel.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_users_panel.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({
    super.key,
  });

  @override
  ConsumerState<AdminShellScreen> createState() =>
      _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  static const _loggerTag = 'AdminShellScreen';

  final TextEditingController _searchController = TextEditingController();

  bool _sidebarExpanded = true;
  bool _isLoggingOut = false;
  AdminShellPage _selectedPage = AdminShellPage.dashboard;
  List<AdminSearchResult> _searchResults = const [];

  @override
  void initState() {
    super.initState();

    AppLogger.debug(
      'Admin shell initialized.',
      tag: _loggerTag,
    );
  }

  @override
  void dispose() {
    AppLogger.debug(
      'Admin shell disposed.',
      tag: _loggerTag,
    );

    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleAccountAction(String action) async {
    if (_isLoggingOut) {
      AppLogger.debug(
        'Account action ignored while logout is active.',
        tag: _loggerTag,
      );
      return;
    }

    AppLogger.debug(
      'Account action selected: $action.',
      tag: _loggerTag,
    );

    if (action == 'password') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ChangePasswordScreen(),
        ),
      );
      return;
    }

    if (action == 'info') {
      final profileState = ref.read(profileControllerProvider);
      final profile = profileState.asData?.value;

      if (profile == null) {
        AppLogger.warning(
          'Profile information was not available for editing.',
          tag: _loggerTag,
        );

        _showMessage(
          'Profile is still loading. Please try again.',
        );
        return;
      }

      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => EditProfileScreen(
            profile: profile,
          ),
        ),
      );

      if (updated == true) {
        AppLogger.info(
          'Profile was updated. Refreshing profile state.',
          tag: _loggerTag,
        );

        try {
          await ref
              .read(profileControllerProvider.notifier)
              .refreshProfile();
        } catch (error, stackTrace) {
          AppLogger.error(
            'Profile refresh failed after profile update.',
            tag: _loggerTag,
            error: error,
            stackTrace: stackTrace,
          );

          if (mounted) {
            _showMessage(
              ErrorMapper.toMessage(
                error,
                stackTrace: stackTrace,
                fallbackMessage:
                    'Profile was updated, but the latest data could not be loaded.',
              ),
            );
          }
        }
      }

      return;
    }

    AppLogger.warning(
      'Unknown account action received: $action.',
      tag: _loggerTag,
    );

    _showMessage(
      'Unknown account action.',
    );
  }

  void _handleSearchChanged(String value) {
    if (_isLoggingOut) {
      return;
    }

    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      if (_searchResults.isEmpty) {
        return;
      }

      setState(() {
        _searchResults = const [];
      });
      return;
    }

    final queryTerms = query
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList(growable: false);

    final matches = AdminSearchCatalog.results.where((result) {
      final haystack = <String>[
        result.title,
        result.description,
        ...result.keywords,
      ].join(' ').toLowerCase();

      return queryTerms.every(haystack.contains);
    }).toList(growable: false);

    setState(() {
      _searchResults = matches;
    });
  }

  void _handleSearchSubmitted(String value) {
    if (_isLoggingOut) {
      return;
    }

    final results = _searchResults;

    if (results.isEmpty) {
      _showMessage('No matching admin page found.');
      return;
    }

    _selectSearchResult(results.first);
  }

  void _selectSearchResult(AdminSearchResult result) {
  if (_isLoggingOut) {
    return;
  }

  setState(() {
    _selectedPage = result.page;
    _searchResults = const [];
  });

  _searchController.clear();

  AppLogger.info(
    'Admin search opened: ${result.title}.',
    tag: _loggerTag,
  );
}

  Future<void> _handleLogout() async {
    if (_isLoggingOut) {
      AppLogger.debug(
        'Duplicate logout action ignored.',
        tag: _loggerTag,
      );
      return;
    }

    setState(() {
      _isLoggingOut = true;
      _searchResults = const [];
    });

    AppLogger.info(
      'Logout started.',
      tag: _loggerTag,
    );

    try {
      await ref.read(authStateProvider.notifier).logout();

      AppLogger.info(
        'Logout completed successfully.',
        tag: _loggerTag,
      );

      if (!mounted) return;

      context.go('/login');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Logout request failed. Redirecting to login anyway.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage:
              'Logout could not be confirmed. Returning to login.',
        ),
      );

      context.go('/login');
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }

      AppLogger.debug(
        'Logout state reset.',
        tag: _loggerTag,
      );
    }
  }

  String _pageTitle(AdminShellPage page) {
    return switch (page) {
      AdminShellPage.dashboard => 'Dashboard',
      AdminShellPage.users => 'Users',
      AdminShellPage.events => 'Events',
      AdminShellPage.categories => 'Categories',
      AdminShellPage.contentModeration => 'Content Moderation',
      AdminShellPage.settings => 'Settings',
    };
  }

  String _pageDescription(AdminShellPage page) {
    return switch (page) {
      AdminShellPage.dashboard =>
        'Quick insight into users, events, and platform activity.',
      AdminShellPage.users =>
        'Monitor and manage platform users.',
      AdminShellPage.events =>
        'Oversee all events across the platform.',
      AdminShellPage.categories =>
        'Create, edit, and manage event categories.',
      AdminShellPage.contentModeration =>
        'Review and manage content reports.',
      AdminShellPage.settings =>
        'Manage desktop application settings.',
    };
  }

  Widget _buildPageContent(
    BuildContext context,
    AdminShellPage page,
  ) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final title = _pageTitle(page);
    final description = _pageDescription(page);

    final Widget content = switch (page) {
      AdminShellPage.dashboard => const AdminDashboardPanel(),
      AdminShellPage.settings => const AdminSettingsPanel(),
      AdminShellPage.users => AdminUsersPanel(
          repository: ref.read(
            adminUsersRepositoryProvider,
          ),
        ),
      AdminShellPage.categories => AdminCategoriesPanel(
          repository: ref.read(
            adminCategoriesRepositoryProvider,
          ),
        ),
      AdminShellPage.events => AdminEventsPanel(
          repository: ref.read(
            adminEventsRepositoryProvider,
          ),
          reverseGeocodingApi: ref.read(
            mapboxReverseGeocodingApiProvider,
          ),
          usersRepository: ref.read(
            adminUsersRepositoryProvider,
          ),
        ),
      AdminShellPage.contentModeration =>
        const AdminReportsPanel(),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(
        28,
        24,
        28,
        28,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ShellBackgroundPainter(
                dotColor: colors.borderSoft,
                waveColor: colors.border,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: content,
              ),
            ],
          ),
          if (_isLoggingOut)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: 0.12,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleSidebar() {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _sidebarExpanded = !_sidebarExpanded;
    });

    AppLogger.debug(
      'Sidebar state changed. Expanded: $_sidebarExpanded.',
      tag: _loggerTag,
    );
  }

  void _selectPage(AdminShellPage page) {
    if (_isLoggingOut) {
      return;
    }

    _searchController.clear();

    if (_selectedPage == page && _searchResults.isEmpty) {
      return;
    }

    setState(() {
      _selectedPage = page;
      _searchResults = const [];
    });

    AppLogger.debug(
      'Admin page selected: ${_pageTitle(page)}.',
      tag: _loggerTag,
    );
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          AdminNavbar(
            searchController: _searchController,
            searchResults: _searchResults,
            onSearchChanged: _handleSearchChanged,
            onSearchSubmitted: _handleSearchSubmitted,
            onSearchResultSelected: _selectSearchResult,
            onAccountSelected: _handleAccountAction,
          ),
          Expanded(
            child: Row(
              children: [
                AdminSidebar(
                  isExpanded: _sidebarExpanded,
                  selectedPage: _selectedPage,
                  onToggle: _toggleSidebar,
                  onSelectPage: _selectPage,
                  onLogout: _handleLogout,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 220,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<AdminShellPage>(
                        _selectedPage,
                      ),
                      child: _buildPageContent(
                        context,
                        _selectedPage,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellBackgroundPainter extends CustomPainter {
  const _ShellBackgroundPainter({
    required this.dotColor,
    required this.waveColor,
  });

  final Color dotColor;
  final Color waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 16.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          1.15,
          dotPaint,
        );
      }
    }

    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path1 = Path()
      ..moveTo(0, size.height - 80)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height - 10,
        size.width * 0.5,
        size.height - 70,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height - 130,
        size.width,
        size.height - 35,
      );

    final path2 = Path()
      ..moveTo(0, size.height - 50)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height + 10,
        size.width * 0.5,
        size.height - 40,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height - 100,
        size.width,
        size.height - 5,
      );

    final path3 = Path()
      ..moveTo(0, size.height - 110)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height - 40,
        size.width * 0.5,
        size.height - 100,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height - 155,
        size.width,
        size.height - 60,
      );

    canvas
      ..drawPath(path1, wavePaint)
      ..drawPath(path2, wavePaint)
      ..drawPath(path3, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _ShellBackgroundPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.waveColor != waveColor;
  }
}