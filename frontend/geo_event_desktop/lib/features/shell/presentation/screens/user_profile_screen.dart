import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/admin_profile/data/admin_users_repository.dart';
import '../../../../shared/admin_profile/models/user_profile.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.repository,
  });

  final int userId;
  final AdminUsersRepository repository;

  @override
  State<UserProfileScreen> createState() => _AdminUserProfileScreenState();
}

class _AdminUserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  AdminUserProfileDetails? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await widget.repository.getUserProfileDetails(widget.userId);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load user profile.';
      });
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0x26000000)
                          : const Color(0x14000000),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildBody(
                  colors: colors,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required AppThemeColors colors,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    if (_isLoading) {
      return SizedBox(
        height: 420,
        child: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    final avatarLetter = profile.fullName.trim().isNotEmpty
        ? profile.fullName.characters.first.toUpperCase()
        : profile.username.characters.firstOrNull?.toUpperCase() ?? 'U';

    final joinedLabel = _formatJoined(profile.createdAt);
    final ratingLabel = profile.averageRating.toStringAsFixed(
      profile.averageRating % 1 == 0 ? 0 : 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'User Profile',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Review account details, public profile information, and admin-visible metadata for this user.',
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: colors.inputFill,
              backgroundImage: profile.hasProfileImage
                  ? NetworkImage(profile.imageUrl!.trim())
                  : null,
              child: !profile.hasProfileImage
                  ? Text(
                      avatarLetter,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName.trim().isEmpty ? 'Unnamed user' : profile.fullName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.displayUsername,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.displayEmail,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoChip(
                        label: profile.role,
                        background: colors.inputFill,
                        foreground: colors.textPrimary,
                      ),
                      _InfoChip(
                        label: profile.isBanned ? 'Banned' : 'Active',
                        background: profile.isBanned
                            ? colorScheme.error.withValues(alpha: 0.10)
                            : colorScheme.primary.withValues(alpha: 0.10),
                        foreground: profile.isBanned
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                      _InfoChip(
                        label: 'Joined $joinedLabel',
                        background: colors.inputFill,
                        foreground: colors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SectionCard(
                title: 'Basic Information',
                icon: Icons.person_outline_rounded,
                child: Column(
                  children: [
                    _InfoRow(label: 'First name', value: _fallback(profile.firstName)),
                    _InfoRow(label: 'Last name', value: _fallback(profile.lastName)),
                    _InfoRow(label: 'Username', value: profile.displayUsername),
                    _InfoRow(label: 'Email', value: profile.displayEmail),
                    _InfoRow(label: 'Phone number', value: profile.displayPhoneNumber),
                    _InfoRow(label: 'Role', value: profile.role),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _SectionCard(
                title: 'Account Status',
                icon: Icons.admin_panel_settings_outlined,
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'User ID',
                      value: profile.userId.toString(),
                    ),
                    _InfoRow(
                      label: 'Ban status',
                      value: profile.isBanned ? 'Banned' : 'Active',
                      valueColor: profile.isBanned
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                    _InfoRow(
                      label: 'Joined',
                      value: joinedLabel,
                    ),
                    _InfoRow(
                      label: 'Events organized',
                      value: profile.eventsCount.toString(),
                    ),
                    _InfoRow(
                      label: 'Average rating',
                      value: '$ratingLabel / 5',
                    ),
                    _InfoRow(
                      label: 'Ratings count',
                      value: profile.ratingsCount.toString(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fallback(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? 'Not provided' : normalized;
  }

  String _formatJoined(DateTime? date) {
    if (date == null) return 'Unknown';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: valueColor ?? colors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}