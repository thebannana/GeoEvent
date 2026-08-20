import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/admin_profile/models/admin_search_result.dart';
import '../../../../shared/admin_profile/models/user_profile.dart';
import '../../application/profile_controller.dart';

class AdminNavbar extends ConsumerStatefulWidget {
  const AdminNavbar({
    super.key,
    required this.onAccountSelected,
    required this.searchController,
    required this.searchResults,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchResultSelected,
  });

  final ValueChanged<String> onAccountSelected;
  final TextEditingController searchController;
  final List<AdminSearchResult> searchResults;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<AdminSearchResult> onSearchResultSelected;

  @override
  ConsumerState<AdminNavbar> createState() => _AdminNavbarState();
}

class _AdminNavbarState extends ConsumerState<AdminNavbar> {
  final LayerLink _searchLayerLink = LayerLink();

  OverlayEntry? _searchOverlay;

  @override
  void didUpdateWidget(covariant AdminNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _updateSearchOverlay();
    });
  }

  @override
  void dispose() {
    _removeSearchOverlay();
    super.dispose();
  }

  void _updateSearchOverlay() {
    final hasSearchQuery =
        widget.searchController.text.trim().isNotEmpty;

    final hasResults = widget.searchResults.isNotEmpty;

    if (!hasSearchQuery || !hasResults) {
      _removeSearchOverlay();
      return;
    }

    _removeSearchOverlay();

    final overlay = Overlay.of(
      context,
      rootOverlay: true,
    );

    _searchOverlay = _buildSearchOverlay();
    overlay.insert(_searchOverlay!);
  }

  void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  OverlayEntry _buildSearchOverlay() {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          width: 420,
          child: CompositedTransformFollower(
            link: _searchLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: Material(
              color: colors.card,
              elevation: 18,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 330,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.borderSoft,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  itemCount: widget.searchResults.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: colors.borderSoft,
                  ),
                  itemBuilder: (context, index) {
                    final result = widget.searchResults[index];

                    return ListTile(
                      dense: true,
                      minVerticalPadding: 10,
                      mouseCursor: SystemMouseCursors.click,
                      leading: Icon(
                        result.icon,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        result.title,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        result.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      onTap: () {
                        _removeSearchOverlay();
                        widget.onSearchResultSelected(result);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.asData?.value;

    final displayName = _displayName(profile);
    final avatarLabel = _avatarLabel(profile);
    final hasSearchText =
        widget.searchController.text.trim().isNotEmpty;

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/geoevent.png',
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: CompositedTransformTarget(
                  link: _searchLayerLink,
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: widget.searchController,
                      onChanged: (value) {
                        widget.onSearchChanged(value);
                      },
                      onSubmitted: (value) {
                        _removeSearchOverlay();
                        widget.onSearchSubmitted(value);
                      },
                      textInputAction: TextInputAction.search,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.inputFill,
                        hoverColor: colors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        hintText: 'Search pages and actions',
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary.withValues(
                            alpha: 0.72,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                        suffixIcon: hasSearchText
                            ? IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  widget.searchController.clear();
                                  _removeSearchOverlay();
                                  widget.onSearchChanged('');
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: colors.textSecondary,
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: colors.borderSoft,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: colors.borderSoft,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          PopupMenuButton<String>(
            tooltip: 'Account',
            offset: const Offset(0, 52),
            color: colors.card,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: widget.onAccountSelected,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'password',
                mouseCursor: SystemMouseCursors.click,
                child: ListTile(
                  mouseCursor: SystemMouseCursors.click,
                  leading: Icon(
                    Icons.lock_outline,
                    color: colors.textSecondary,
                  ),
                  title: Text(
                    'Change password',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'info',
                mouseCursor: SystemMouseCursors.click,
                child: ListTile(
                  mouseCursor: SystemMouseCursors.click,
                  leading: Icon(
                    Icons.person_outline,
                    color: colors.textSecondary,
                  ),
                  title: Text(
                    'Change account information',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colors.inputFill.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.borderSoft,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavbarAvatar(
                      imageUrl: profile?.imageUrl,
                      fallbackLabel: avatarLabel,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      displayName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(UserProfile? profile) {
    final username = profile?.username.trim() ?? '';
    if (username.isNotEmpty) {
      return username;
    }

    final fullName = profile?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return 'Account';
  }

  String _avatarLabel(UserProfile? profile) {
    final source = [
      profile?.firstName ?? '',
      profile?.lastName ?? '',
      profile?.username ?? '',
      profile?.email ?? '',
    ].firstWhere(
      (value) => value.trim().isNotEmpty,
      orElse: () => 'A',
    );

    return source.trim().characters.first.toUpperCase();
  }
}

class _NavbarAvatar extends StatelessWidget {
  const _NavbarAvatar({
    required this.imageUrl,
    required this.fallbackLabel,
  });

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final trimmedUrl = imageUrl?.trim();

    return CircleAvatar(
      radius: 18,
      backgroundColor: colors.inputFill,
      backgroundImage: trimmedUrl != null && trimmedUrl.isNotEmpty
          ? NetworkImage(trimmedUrl)
          : null,
      child: trimmedUrl == null || trimmedUrl.isEmpty
          ? Text(
              fallbackLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            )
          : null,
    );
  }
}