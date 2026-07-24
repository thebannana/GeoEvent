import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
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
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _sidebarExpanded = true;
  bool _isLoggingOut = false;
  AdminShellPage _selectedPage = AdminShellPage.dashboard;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleAccountAction(String action) async {
  if (action == 'password') {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ),
    );
    return;
  }

  if (action == 'info') {
    final profileState = ref.read(profileControllerProvider);
    final profile = profileState.asData?.value;

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile is still loading. Please try again.'),
        ),
      );
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: profile),
      ),
    );

    if (updated == true) {
      await ref.read(profileControllerProvider.notifier).refreshProfile();
    }

    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Unknown account action.'),
    ),
  );
}

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref.read(authStateProvider.notifier).logout();

      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      context.go('/login');
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  String _pageTitle(AdminShellPage page) {
    switch (page) {
      case AdminShellPage.dashboard:
        return 'Dashboard';
      case AdminShellPage.users:
        return 'Users';
      case AdminShellPage.events:
        return 'Events';
      case AdminShellPage.categories:
        return 'Categories';
      case AdminShellPage.contentModeration:
        return 'Content Moderation';
      case AdminShellPage.settings:
        return 'Settings';
    }
  }

  String _pageDescription(AdminShellPage page) {
    switch (page) {
      case AdminShellPage.dashboard:
        return 'Quick insight into users, events, and platform activity.';
      case AdminShellPage.users:
        return 'Monitor and manage platform users.';
      case AdminShellPage.events:
        return 'Oversee all events across the platform.';
      case AdminShellPage.categories:
        return 'Create, edit, and manage event categories.';
      case AdminShellPage.contentModeration:
        return 'Review and manage content reports.';
      case AdminShellPage.settings:
        return 'Manage desktop application settings.';
    }
  }

  Widget _buildPageContent(BuildContext context, AdminShellPage page) {
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
      repository: ref.read(adminUsersRepositoryProvider),
    ),
  AdminShellPage.categories => AdminCategoriesPanel(
      repository: ref.read(adminCategoriesRepositoryProvider),
    ),
  AdminShellPage.events => AdminEventsPanel(
      repository: ref.read(adminEventsRepositoryProvider),
      reverseGeocodingApi: ref.read(mapboxReverseGeocodingApiProvider),
      usersRepository: ref.read(adminUsersRepositoryProvider),
    ),
  AdminShellPage.contentModeration => const AdminReportsPanel(),
};

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 24, 28, 28),
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
              Expanded(child: content),
            ],
          ),
          if (_isLoggingOut)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.12),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          AdminNavbar(
            searchController: _searchController,
            onAccountSelected: _handleAccountAction,
          ),
          Expanded(
            child: Row(
              children: [
                AdminSidebar(
                  isExpanded: _sidebarExpanded,
                  selectedPage: _selectedPage,
                  onToggle: () {
                    setState(() {
                      _sidebarExpanded = !_sidebarExpanded;
                    });
                  },
                  onSelectPage: (page) {
                    setState(() {
                      _selectedPage = page;
                    });
                  },
                  onLogout: _handleLogout,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedPage),
                      child: _buildPageContent(context, _selectedPage),
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
        canvas.drawCircle(Offset(x, y), 1.15, dotPaint);
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

    canvas.drawPath(path1, wavePaint);
    canvas.drawPath(path2, wavePaint);
    canvas.drawPath(path3, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}