import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/color_parser.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/admin_profile/data/admin_categories_repository.dart';
import '../../../../shared/admin_profile/models/categories.dart';
import '../screens/edit_category_screen.dart';

enum AdminCategoryType {
  segment,
  genre,
  subGenre;

  String get buttonLabel {
    switch (this) {
      case AdminCategoryType.segment:
        return 'segment';
      case AdminCategoryType.genre:
        return 'genre';
      case AdminCategoryType.subGenre:
        return 'subgenre';
    }
  }

  String get titleLabel {
    switch (this) {
      case AdminCategoryType.segment:
        return 'Segments';
      case AdminCategoryType.genre:
        return 'Genres';
      case AdminCategoryType.subGenre:
        return 'Subgenres';
    }
  }
}

class CategoryEditorResult {
  const CategoryEditorResult({
    required this.type,
    required this.name,
    required this.isActive,
    this.row,
    this.color,
    this.parentId,
  });

  final AdminCategoryRowData? row;
  final AdminCategoryType type;
  final String name;
  final String? color;
  final int? parentId;
  final bool isActive;
}

class AdminCategoryRowData {
  const AdminCategoryRowData({
    required this.id,
    required this.type,
    required this.name,
    required this.isActive,
    this.parentId,
    this.parentName,
    this.secondaryParentName,
    this.color,
  });

  final int id;
  final AdminCategoryType type;
  final String name;
  final bool isActive;
  final int? parentId;
  final String? parentName;
  final String? secondaryParentName;
  final String? color;

  factory AdminCategoryRowData.segment({
    required int segmentId,
    required String name,
    required String? color,
    required bool isActive,
  }) {
    return AdminCategoryRowData(
      id: segmentId,
      type: AdminCategoryType.segment,
      name: name,
      color: color,
      isActive: isActive,
    );
  }

  factory AdminCategoryRowData.genre({
    required int genreId,
    required int segmentId,
    required String parentName,
    required String name,
    required bool isActive,
  }) {
    return AdminCategoryRowData(
      id: genreId,
      type: AdminCategoryType.genre,
      name: name,
      parentId: segmentId,
      parentName: parentName,
      isActive: isActive,
    );
  }

  factory AdminCategoryRowData.subGenre({
    required int subGenreId,
    required int genreId,
    required String parentName,
    required String secondaryParentName,
    required String name,
    required bool isActive,
  }) {
    return AdminCategoryRowData(
      id: subGenreId,
      type: AdminCategoryType.subGenre,
      name: name,
      parentId: genreId,
      parentName: parentName,
      secondaryParentName: secondaryParentName,
      isActive: isActive,
    );
  }
}

class AdminCategoriesPanel extends StatefulWidget {
  const AdminCategoriesPanel({
    super.key,
    required this.repository,
  });

  final AdminCategoriesRepository repository;

  @override
  State<AdminCategoriesPanel> createState() => _AdminCategoriesPanelState();
}

class _AdminCategoriesPanelState extends State<AdminCategoriesPanel> {
  static const _loggerTag = 'AdminCategoriesPanel';
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();

  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 350),
  );

  List<AdminSegment> _segments = const [];
  List<AdminCategoryRowData> _rows = const [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  AdminCategoryType _selectedType = AdminCategoryType.segment;

  int _currentPage = 1;
  int _totalCount = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureSegmentsLoaded() async {
    if (_segments.isNotEmpty) return;
    _segments = await widget.repository.getSegments();
  }

  Future<void> _loadCategories({
    bool showLoader = true,
    int? page,
  }) async {
    final targetPage = page ?? _currentPage;

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
      await _ensureSegmentsLoaded();

      final query = _searchController.text.trim();

      late final List<AdminCategoryRowData> rows;
      late final int totalCount;
      late final int resolvedPage;
      late final int resolvedPageSize;

      switch (_selectedType) {
        case AdminCategoryType.segment:
          final result = await widget.repository.getSegmentsPage(
            page: targetPage,
            pageSize: _pageSize,
            searchTerm: query.isEmpty ? null : query,
          );
          rows = result.items
              .map(
                (segment) => AdminCategoryRowData.segment(
                  segmentId: segment.segmentId,
                  name: segment.name,
                  color: segment.color,
                  isActive: segment.isActive,
                ),
              )
              .toList();
          totalCount = result.totalCount;
          resolvedPage = result.page;
          resolvedPageSize = result.pageSize;
          break;

        case AdminCategoryType.genre:
          final result = await widget.repository.getGenresPage(
            page: targetPage,
            pageSize: _pageSize,
            searchTerm: query.isEmpty ? null : query,
          );
          rows = result.items
              .map(
                (genre) => AdminCategoryRowData.genre(
                  genreId: genre.genreId,
                  segmentId: genre.segmentId,
                  parentName: genre.segmentName ?? '—',
                  name: genre.name,
                  isActive: genre.isActive,
                ),
              )
              .toList();
          totalCount = result.totalCount;
          resolvedPage = result.page;
          resolvedPageSize = result.pageSize;
          break;

        case AdminCategoryType.subGenre:
          final result = await widget.repository.getSubGenresPage(
            page: targetPage,
            pageSize: _pageSize,
            searchTerm: query.isEmpty ? null : query,
          );

          rows = result.items
              .map(
                (subGenre) => AdminCategoryRowData.subGenre(
                  subGenreId: subGenre.subGenreId,
                  genreId: subGenre.genreId,
                  parentName: subGenre.genreName ?? '—',
                  secondaryParentName: subGenre.segmentName ?? '—',
                  name: subGenre.name,
                  isActive: subGenre.isActive,
                ),
              )
              .toList();
          totalCount = result.totalCount;
          resolvedPage = result.page;
          resolvedPageSize = result.pageSize;
          break;
      }

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _totalCount = totalCount;
        _currentPage = resolvedPage;
        _totalPages = totalCount == 0
            ? 1
            : (totalCount / (resolvedPageSize <= 0 ? _pageSize : resolvedPageSize))
                .ceil()
                .clamp(1, 999999);
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load categories.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load categories.';
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebouncer.run(() {
      if (!mounted) return;
      _loadCategories(page: 1);
    });
  }

  void _clearSearch() {
    _searchDebouncer.cancel();
    _searchController.clear();
    _loadCategories(page: 1);
  }

  void _setType(AdminCategoryType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
    });
    _loadCategories(page: 1);
  }

  void _goToPreviousPage() {
    if (_currentPage <= 1 || _isLoading) return;
    _loadCategories(showLoader: false, page: _currentPage - 1);
  }

  void _goToNextPage() {
    if (_currentPage >= _totalPages || _isLoading) return;
    _loadCategories(showLoader: false, page: _currentPage + 1);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateScreen() async {
    await _ensureSegmentsLoaded();

    final result = await Navigator.of(context).push<CategoryEditorResult>(
      MaterialPageRoute(
        builder: (_) => EditCategoryScreen(
          type: _selectedType,
          segments: _segments,
        ),
      ),
    );

    if (result == null || !mounted) return;
    await _saveCategory(result);
  }

  Future<void> _openEditScreen(AdminCategoryRowData row) async {
    await _ensureSegmentsLoaded();

    final result = await Navigator.of(context).push<CategoryEditorResult>(
      MaterialPageRoute(
        builder: (_) => EditCategoryScreen(
          type: row.type,
          segments: _segments,
          initialRow: row,
        ),
      ),
    );

    if (result == null || !mounted) return;
    await _saveCategory(result);
  }

  Future<void> _saveCategory(CategoryEditorResult result) async {
    setState(() => _isSaving = true);

    try {
      switch (result.type) {
        case AdminCategoryType.segment:
          if (result.row == null) {
            await widget.repository.createSegment(
              name: result.name,
              color: result.color,
              isActive: result.isActive,
            );
            _showSnack('Segment created successfully.');
          } else {
            await widget.repository.updateSegment(
              segmentId: result.row!.id,
              name: result.name,
              color: result.color,
              isActive: result.isActive,
            );
            _showSnack('Segment updated successfully.');
          }
          break;

        case AdminCategoryType.genre:
          if (result.row == null) {
            await widget.repository.createGenre(
              segmentId: result.parentId!,
              name: result.name,
              isActive: result.isActive,
            );
            _showSnack('Genre created successfully.');
          } else {
            await widget.repository.updateGenre(
              genreId: result.row!.id,
              segmentId: result.parentId,
              name: result.name,
              isActive: result.isActive,
            );
            _showSnack('Genre updated successfully.');
          }
          break;

        case AdminCategoryType.subGenre:
          if (result.row == null) {
            await widget.repository.createSubGenre(
              genreId: result.parentId!,
              name: result.name,
              isActive: result.isActive,
            );
            _showSnack('Subgenre created successfully.');
          } else {
            await widget.repository.updateSubGenre(
              subGenreId: result.row!.id,
              genreId: result.parentId,
              name: result.name,
              isActive: result.isActive,
            );
            _showSnack('Subgenre updated successfully.');
          }
          break;
      }

      _segments = const [];
      await _loadCategories(showLoader: false, page: 1);
    } catch (_) {
      _showSnack('Failed to save category changes.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String get _typeLabel => _selectedType.titleLabel;

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
                    hintText: 'Search $_typeLabel',
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
              PopupMenuButton<AdminCategoryType>(
                tooltip: 'Select category type',
                initialValue: _selectedType,
                onSelected: _setType,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: AdminCategoryType.segment,
                    child: Text('Segments'),
                  ),
                  PopupMenuItem(
                    value: AdminCategoryType.genre,
                    child: Text('Genres'),
                  ),
                  PopupMenuItem(
                    value: AdminCategoryType.subGenre,
                    child: Text('Subgenres'),
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
                        Icons.tune_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _typeLabel,
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _openCreateScreen,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Add ${_selectedType.buttonLabel}'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                  '$_totalCount items',
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
                                onPressed: _loadCategories,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _rows.isEmpty
                          ? Center(
                              child: Text(
                                'No $_typeLabel found.',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                Column(
                                  children: [
                                    CategoriesTableHeader(
                                      colors: colors,
                                      textTheme: textTheme,
                                      type: _selectedType,
                                    ),
                                    Divider(
                                      height: 1,
                                      color: colors.borderSoft,
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        itemCount: _rows.length,
                                        separatorBuilder: (_, _) => Divider(
                                          height: 1,
                                          indent: 18,
                                          endIndent: 18,
                                          color: colors.borderSoft.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        itemBuilder: (context, index) {
                                          final row = _rows[index];
                                          return CategoryRow(
                                            row: row,
                                            onEdit: () => _openEditScreen(row),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isSaving)
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
          _CategoryPaginationFooter(
            currentPage: _currentPage,
            totalPages: _totalPages,
            isLoading: _isLoading,
            onPrevious: _goToPreviousPage,
            onNext: _goToNextPage,
          ),
        ],
      ),
    );
  }
}

class CategoriesTableHeader extends StatelessWidget {
  const CategoriesTableHeader({
    super.key,
    required this.colors,
    required this.textTheme,
    required this.type,
  });

  final AppThemeColors colors;
  final TextTheme textTheme;
  final AdminCategoryType type;

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
          Expanded(
            flex: 3,
            child: Text(
              switch (type) {
                AdminCategoryType.segment => 'Segment name',
                AdminCategoryType.genre => 'Genre name',
                AdminCategoryType.subGenre => 'Subgenre name',
              },
              style: style,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              switch (type) {
                AdminCategoryType.segment => 'Color',
                AdminCategoryType.genre => 'Segment',
                AdminCategoryType.subGenre => 'Genre / Segment',
              },
              style: style,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('Status', style: style),
          ),
          SizedBox(
            width: 96,
            child: Text(
              'Actions',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.row,
    required this.onEdit,
  });

  final AdminCategoryRowData row;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final statusBackground = row.isActive
        ? colorScheme.primary.withValues(alpha: 0.10)
        : colorScheme.error.withValues(alpha: 0.10);

    final statusColor =
        row.isActive ? colorScheme.primary : colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.name,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: row.type == AdminCategoryType.segment
                ? Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _parseColor(row.color) ??
                              colorScheme.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: colors.borderSoft),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          row.color ?? '—',
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : row.type == AdminCategoryType.genre
                    ? Text(
                        row.parentName ?? '—',
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.parentName ?? '—',
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.secondaryParentName ?? '—',
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  row.isActive ? 'Active' : 'Inactive',
                  style: textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionIconButton(
                  tooltip: 'Edit',
                  icon: Icons.edit_outlined,
                  color: colors.textSecondary,
                  onTap: onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color? _parseColor(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return ColorParser.parseHex(value);
  }
}

class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
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
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _CategoryPaginationFooter extends StatelessWidget {
  const _CategoryPaginationFooter({
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

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
          onPressed: currentPage > 1 && !isLoading ? onPrevious : null,
          child: const Text('Previous'),
        ),
        const SizedBox(width: 12),
        pageChip('$currentPage', active: true),
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
          onPressed: currentPage < totalPages && !isLoading ? onNext : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}