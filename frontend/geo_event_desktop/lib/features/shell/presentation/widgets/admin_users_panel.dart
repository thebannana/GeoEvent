import 'package:flutter/material.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/admin_profile/data/admin_users_repository.dart';
import '../../../../shared/admin_profile/models/user_profile.dart';
import '../screens/edit_user_screen.dart';
import '../screens/user_profile_screen.dart';

class AdminUsersPanel extends StatefulWidget {
  const AdminUsersPanel({
    super.key,
    required this.repository,
  });

  final AdminUsersRepository repository;

  @override
  State<AdminUsersPanel> createState() => _AdminUsersPanelState();
}

class _AdminUsersPanelState extends State<AdminUsersPanel> {
  static const _loggerTag = 'AdminUsersPanel';

  static const _allRolesFilter = '__all_roles__';
  static const _allStatusesFilter = '__all_statuses__';
  static const _activeStatusFilter = '__active__';
  static const _bannedStatusFilter = '__banned__';

  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 450),
  );

  List<_AdminUserRowData> _users = const [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  int _page = 1;
  final int _pageSize = 10;
  int _totalCount = 0;

  // null means: do not apply that filter.
  String? _roleFilter;
  bool? _isBannedFilter;

  @override
  void initState() {
    super.initState();

    // Keep both filters null so the initial request is truly "All users".
    _loadUsers();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({int? page, bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      final result = await widget.repository.getUsers(
        page: page ?? _page,
        pageSize: _pageSize,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        role: _roleFilter,
        isBanned: _isBannedFilter,
      );

      if (!mounted) return;

      setState(() {
        _page = result.page;
        _totalCount = result.totalCount;
        _users = result.items.map(_AdminUserRowData.fromProfile).toList();
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load users list.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load users.';
      });
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});

    _searchDebouncer.run(() {
      if (!mounted) return;
      _loadUsers(page: 1);
    });
  }

  Future<void> _clearSearch() async {
    _searchDebouncer.cancel();
    _searchController.clear();

    setState(() {});

    await _loadUsers(page: 1);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _openUserProfile(_AdminUserRowData user) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: user.userId,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(_AdminUserRowData user) async {
    final colors = Theme.of(context).appColors;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Delete user'),
          content: Text(
            'Are you sure you want to delete ${user.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() => _isActionLoading = true);

    try {
      await widget.repository.deleteUser(user.userId);

      await _loadUsers(
        page: _users.length == 1 && _page > 1 ? _page - 1 : _page,
        showLoader: false,
      );

      if (!mounted) return;
      _showSnack('${user.displayName} deleted successfully.');
    } catch (error, stackTrace) {
  AppLogger.error(
    'Failed to delete user ${user.userId}.',
    tag: _loggerTag,
    error: error,
    stackTrace: stackTrace,
  );

  if (!mounted) return;

  _showSnack(
    ErrorMapper.toMessage(
      error,
      stackTrace: stackTrace,
      fallbackMessage:
          'Could not delete ${user.displayName}. Please try again.',
    ),
  );
} finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _toggleBan(_AdminUserRowData user) async {
    setState(() => _isActionLoading = true);

    try {
      if (user.isBanned) {
        await widget.repository.unbanUser(user.userId);
      } else {
        await widget.repository.banUser(user.userId);
      }

      await _loadUsers(showLoader: false);

      if (!mounted) return;

      _showSnack(
        user.isBanned
            ? '${user.displayName} unbanned successfully.'
            : '${user.displayName} banned successfully.',
      );
    } catch (error, stackTrace) {
  AppLogger.error(
    user.isBanned
        ? 'Failed to unban ${user.displayName}.'
        : 'Failed to ban ${user.displayName}.',
    tag: _loggerTag,
    error: error,
    stackTrace: stackTrace,
  );

  if (!mounted) return;

  _showSnack(
    ErrorMapper.toMessage(
      error,
      stackTrace: stackTrace,
      fallbackMessage: user.isBanned
          ? 'Could not unban ${user.displayName}. Please try again.'
          : 'Could not ban ${user.displayName}. Please try again.',
    ),
  );
} finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _editUser(_AdminUserRowData user) async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => EditUserScreen(
          profile: user.profile,
          repository: widget.repository,
        ),
      ),
    );

    if (updated != null && mounted) {
      await _loadUsers(showLoader: false);
      _showSnack('${updated.username} updated successfully.');
    }
  }

  Future<void> _setBannedFilter(bool? value) async {
    setState(() {
      _isBannedFilter = value;
    });

    await _loadUsers(page: 1);
  }

  Future<void> _setRoleFilter(String? value) async {
    setState(() {
      _roleFilter = value;
    });

    await _loadUsers(page: 1);
  }

  int get _totalPages {
    if (_totalCount == 0) return 1;
    return (_totalCount / _pageSize).ceil();
  }

  String _roleFilterLabel() {
    if (_roleFilter == null) return 'All roles';
    return _roleFilter!;
  }

  String _statusFilterLabel() {
    if (_isBannedFilter == null) return 'All';
    return _isBannedFilter! ? 'Banned' : 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? const Color(0x16000000)
                : const Color(0x12000000),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search users',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: colors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: colors.borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.45),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Filter by status',
                onSelected: (value) {
                  final bool? bannedFilter = switch (value) {
                    _allStatusesFilter => null,
                    _activeStatusFilter => false,
                    _bannedStatusFilter => true,
                    _ => null,
                  };

                  _setBannedFilter(bannedFilter);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: _allStatusesFilter,
                    child: Text('All users'),
                  ),
                  PopupMenuItem<String>(
                    value: _activeStatusFilter,
                    child: Text('Active only'),
                  ),
                  PopupMenuItem<String>(
                    value: _bannedStatusFilter,
                    child: Text('Banned only'),
                  ),
                ],
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.borderSoft),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: _isBannedFilter == null
                            ? colors.textSecondary
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusFilterLabel(),
                        style: textTheme.labelLarge?.copyWith(
                          color: _isBannedFilter == null
                              ? colors.textSecondary
                              : colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Filter by role',
                onSelected: (value) {
                  _setRoleFilter(
                    value == _allRolesFilter ? null : value,
                  );
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: _allRolesFilter,
                    child: Text('All roles'),
                  ),
                  PopupMenuItem<String>(
                    value: AppRoles.user,
                    child: Text(AppRoles.user),
                  ),
                  PopupMenuItem<String>(
                    value: AppRoles.admin,
                    child: Text(AppRoles.admin),
                  ),
                ],
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.borderSoft),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: _roleFilter == null
                            ? colors.textSecondary
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _roleFilterLabel(),
                        style: textTheme.labelLarge?.copyWith(
                          color: _roleFilter == null
                              ? colors.textSecondary
                              : colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.borderSoft),
                ),
                child: Text(
                  '$_totalCount users',
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: colors.borderSoft.withValues(alpha: 0.9),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _errorMessage!,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => _loadUsers(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _users.isEmpty
                          ? Center(
                              child: Text(
                                'No users found.',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                Positioned.fill(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(22),
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: constraints.maxWidth,
                                              ),
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth < 1220
                                                        ? 1220
                                                        : constraints.maxWidth,
                                                child: Column(
                                                  children: [
                                                    _UsersTableHeader(
                                                      colors: colors,
                                                      textTheme: textTheme,
                                                    ),
                                                    Divider(
                                                      height: 1,
                                                      color:
                                                          colors.borderSoft,
                                                    ),
                                                    Expanded(
                                                      child: ListView.separated(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 6,
                                                        ),
                                                        itemCount:
                                                            _users.length,
                                                        separatorBuilder:
                                                            (_, _) => Divider(
                                                          height: 1,
                                                          indent: 18,
                                                          endIndent: 18,
                                                          color: colors
                                                              .borderSoft
                                                              .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                        ),
                                                        itemBuilder:
                                                            (context, index) {
                                                          final user =
                                                              _users[index];

                                                          return _UserRow(
                                                            user: user,
                                                            onViewProfile: () =>
                                                                _openUserProfile(
                                                              user,
                                                            ),
                                                            onEdit: () =>
                                                                _editUser(
                                                              user,
                                                            ),
                                                            onDelete: () =>
                                                                _confirmDelete(
                                                              user,
                                                            ),
                                                            onToggleBan: () =>
                                                                _toggleBan(
                                                              user,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_isActionLoading)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(22),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
            ),
          ),
          const SizedBox(height: 16),
          _UsersPagination(
            page: _page,
            totalPages: _totalPages,
            onPrevious: _page > 1 ? () => _loadUsers(page: _page - 1) : null,
            onNext:
                _page < _totalPages ? () => _loadUsers(page: _page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _UsersTableHeader extends StatelessWidget {
  const _UsersTableHeader({
    required this.colors,
    required this.textTheme,
  });

  final AppThemeColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final style = textTheme.labelMedium?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Full name', style: style)),
          Expanded(flex: 2, child: Text('Phone number', style: style)),
          Expanded(flex: 3, child: Text('Email', style: style)),
          Expanded(flex: 2, child: Text('Username', style: style)),
          Expanded(flex: 2, child: Text('Role', style: style)),
          Expanded(flex: 2, child: Text('Status', style: style)),
          const SizedBox(
            width: 200,
            child: Text(
              'Actions',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onViewProfile,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleBan,
  });

  final _AdminUserRowData user;
  final VoidCallback onViewProfile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleBan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _UserAvatar(
                  imageUrl: user.avatarUrl,
                  fullName: user.displayName,
                  username: user.username,
                  isBanned: user.isBanned,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      decoration:
                          user.isBanned ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.phoneNumber.isEmpty ? '—' : user.phoneNumber,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.email,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.displayUsername,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.role,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: user.isBanned
                      ? colorScheme.error.withValues(alpha: 0.10)
                      : colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user.isBanned ? 'Banned' : 'Active',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: user.isBanned
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionIconButton(
                  tooltip: 'View profile',
                  icon: Icons.visibility_outlined,
                  color: colorScheme.primary,
                  onTap: onViewProfile,
                ),
                const SizedBox(width: 6),
                _ActionIconButton(
                  tooltip: 'Edit user',
                  icon: Icons.edit_outlined,
                  color: colors.textSecondary,
                  onTap: onEdit,
                ),
                const SizedBox(width: 6),
                _ActionIconButton(
                  tooltip: user.isBanned ? 'Unban user' : 'Ban user',
                  icon: user.isBanned
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  color: user.isBanned
                      ? colorScheme.primary
                      : Colors.orange.shade700,
                  onTap: onToggleBan,
                ),
                const SizedBox(width: 6),
                _ActionIconButton(
                  tooltip: 'Delete user',
                  icon: Icons.delete_outline_rounded,
                  color: colorScheme.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSoft),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _UsersPagination extends StatelessWidget {
  const _UsersPagination({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    Widget pageChip(String label, {bool active = false}) {
      return Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? null : Border.all(color: colors.borderSoft),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: active ? colors.card : colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onPrevious,
          child: const Text('Previous'),
        ),
        const SizedBox(width: 12),
        pageChip('$page', active: true),
        const SizedBox(width: 10),
        Text(
          'of $totalPages',
          style: textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onNext,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _AdminUserRowData {
  const _AdminUserRowData({
    required this.profile,
  });

  final UserProfile profile;

  factory _AdminUserRowData.fromProfile(UserProfile profile) {
    return _AdminUserRowData(profile: profile);
  }

  int get userId => profile.userId;

  String get fullName => '${profile.firstName} ${profile.lastName}'.trim();

  String get displayName {
    final value = fullName.trim();
    if (value.isNotEmpty) return value;

    final username = profile.username.trim();
    if (username.isNotEmpty) return username;

    return 'Unnamed user';
  }

  String get phoneNumber => profile.phoneNumber ?? '';

  String get email => profile.email.trim().isEmpty ? 'No email' : profile.email;

  String get username => profile.username;

  String get displayUsername {
    final value = profile.username.trim();
    if (value.isEmpty) return '@user';
    return value.startsWith('@') ? value : '@$value';
  }

  String get role => profile.role.trim().isEmpty ? 'User' : profile.role;

  bool get isBanned => profile.isBanned;

  String? get avatarUrl => profile.imageUrl;
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.imageUrl,
    required this.fullName,
    required this.username,
    required this.isBanned,
  });

  final String? imageUrl;
  final String fullName;
  final String username;
  final bool isBanned;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final normalizedUrl = imageUrl?.trim();
    final hasImage = normalizedUrl != null && normalizedUrl.isNotEmpty;

    final normalizedName = fullName.trim();
    final normalizedUsername = username.trim();

    final initial = normalizedName.isNotEmpty
        ? normalizedName.characters.first.toUpperCase()
        : (normalizedUsername.isNotEmpty
            ? normalizedUsername.characters.first.toUpperCase()
            : 'U');

    final fallbackBackground = isBanned
        ? colorScheme.error.withValues(alpha: 0.12)
        : const Color(0xFFF3EAFE);

    final fallbackForeground =
        isBanned ? colorScheme.error : const Color(0xFF7C66B3);

    Widget fallback() {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: fallbackBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: fallbackForeground,
          ),
        ),
      );
    }

    if (!hasImage) return fallback();

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isBanned
              ? colorScheme.error.withValues(alpha: 0.22)
              : Colors.transparent,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          normalizedUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return fallback();
          },
        ),
      ),
    );
  }
}