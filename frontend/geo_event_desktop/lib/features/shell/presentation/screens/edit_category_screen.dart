import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/utils/color_parser.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/admin_profile/models/categories.dart';
import '../widgets/admin_categories_panel.dart';

class EditCategoryScreen extends StatefulWidget {
  const EditCategoryScreen({
    super.key,
    required this.type,
    required this.segments,
    this.initialRow,
  });

  final AdminCategoryType type;
  final List<AdminSegment> segments;
  final AdminCategoryRowData? initialRow;

  @override
  State<EditCategoryScreen> createState() =>
      _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  static const _loggerTag = 'EditCategoryScreen';

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  int? _selectedSegmentId;
  int? _selectedGenreId;

  bool _isActive = true;
  bool _isSubmitting = false;

  Color _selectedColor = const Color(0xFF8E7CFF);

  @override
  void initState() {
    super.initState();

    final row = widget.initialRow;

    _nameController = TextEditingController(
      text: row?.name ?? '',
    );

    _isActive = row?.isActive ?? true;
    _selectedColor =
        _parseColor(row?.color) ?? const Color(0xFF8E7CFF);

    if (widget.type == AdminCategoryType.genre) {
      _selectedSegmentId = row?.parentId;
    }

    if (widget.type == AdminCategoryType.subGenre) {
      _selectedGenreId = row?.parentId;

      if (_selectedGenreId != null) {
        for (final segment in widget.segments) {
          for (final genre in segment.genres) {
            if (genre.genreId == _selectedGenreId) {
              _selectedSegmentId = genre.segmentId;
              break;
            }
          }
        }
      }
    }

    AppLogger.debug(
      'Category editor initialized for ${widget.type}.',
      tag: _loggerTag,
    );
  }

  @override
  void dispose() {
    AppLogger.debug(
      'Category editor disposed.',
      tag: _loggerTag,
    );

    _nameController.dispose();
    super.dispose();
  }

  List<AdminGenre> get _availableGenres {
    final segmentId = _selectedSegmentId;

    if (segmentId == null) {
      return const [];
    }

    for (final segment in widget.segments) {
      if (segment.segmentId == segmentId) {
        return segment.genres;
      }
    }

    return const [];
  }

  String get _screenTitle {
    return widget.initialRow == null
        ? 'Add ${widget.type.buttonLabel}'
        : 'Edit ${widget.type.buttonLabel}';
  }

  String get _screenDescription {
    return switch (widget.type) {
      AdminCategoryType.segment =>
        'Update the segment name, accent color, and visibility used across the platform.',
      AdminCategoryType.genre =>
        'Update the genre name and assign it to the appropriate segment.',
      AdminCategoryType.subGenre =>
        'Update the subgenre name and connect it to the correct segment and genre.',
    };
  }

  String get _typeLabel {
    return switch (widget.type) {
      AdminCategoryType.segment => 'Segment',
      AdminCategoryType.genre => 'Genre',
      AdminCategoryType.subGenre => 'Subgenre',
    };
  }

  String? _validateName(String? value) {
    return Validators.requiredField(
      value,
      fieldName: 'Name',
    );
  }

  Future<void> _pickColor() async {
    if (_isSubmitting) {
      return;
    }

    AppLogger.debug(
      'Category color picker opened.',
      tag: _loggerTag,
    );

    try {
      final picked = await showColorPickerDialog(
        context,
        _selectedColor,
        pickersEnabled: const <ColorPickerType, bool>{
          ColorPickerType.wheel: true,
          ColorPickerType.primary: false,
          ColorPickerType.accent: false,
          ColorPickerType.bw: false,
          ColorPickerType.both: false,
          ColorPickerType.custom: false,
        },
        enableShadesSelection: false,
        showColorCode: true,
        colorCodeHasColor: true,
        showRecentColors: false,
        enableOpacity: false,
        borderRadius: 20,
        wheelDiameter: 220,
        wheelWidth: 18,
        actionButtons: const ColorPickerActionButtons(
          okButton: true,
          closeButton: true,
          dialogActionButtons: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _selectedColor = picked;
      });

      AppLogger.debug(
        'Category color changed to ${_toHex(_selectedColor)}.',
        tag: _loggerTag,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Category color picker failed.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        'Unable to select a category color.',
      );
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      AppLogger.debug(
        'Duplicate category-submit action ignored.',
        tag: _loggerTag,
      );
      return;
    }

    final form = _formKey.currentState;

    if (form == null) {
      AppLogger.warning(
        'Category form state was unavailable.',
        tag: _loggerTag,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (!form.validate()) {
      AppLogger.debug(
        'Category form validation failed.',
        tag: _loggerTag,
      );
      return;
    }

    if (!_validateParentSelection()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    AppLogger.info(
      'Category save started.',
      tag: _loggerTag,
    );

    final result = CategoryEditorResult(
      row: widget.initialRow,
      type: widget.type,
      name: _nameController.text.trim(),
      color: widget.type == AdminCategoryType.segment
          ? _toHex(_selectedColor)
          : null,
      parentId: switch (widget.type) {
        AdminCategoryType.segment => null,
        AdminCategoryType.genre => _selectedSegmentId,
        AdminCategoryType.subGenre => _selectedGenreId,
      },
      isActive: _isActive,
    );

    if (!mounted) return;

    AppLogger.info(
      'Category save completed successfully.',
      tag: _loggerTag,
    );

    context.pop(result);
  }

  bool _validateParentSelection() {
    if (widget.type == AdminCategoryType.genre &&
        _selectedSegmentId == null) {
      _showMessage('Please select a segment.');
      return false;
    }

    if (widget.type == AdminCategoryType.subGenre &&
        _selectedSegmentId == null) {
      _showMessage('Please select a segment.');
      return false;
    }

    if (widget.type == AdminCategoryType.subGenre &&
        _selectedGenreId == null) {
      _showMessage('Please select a genre.');
      return false;
    }

    return true;
  }

  void _handleSegmentChanged(int? segmentId) {
    setState(() {
      _selectedSegmentId = segmentId;

      if (widget.type == AdminCategoryType.subGenre) {
        _selectedGenreId = null;
      }
    });
  }

  void _handleGenreChanged(int? genreId) {
    setState(() {
      _selectedGenreId = genreId;
    });
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

  Color? _parseColor(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return ColorParser.parseHex(value);
  }

  String _toHex(Color color) {
    final value = color.toARGB32().toRadixString(16).toUpperCase();

    return '#${value.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final previewName = _nameController.text.trim().isEmpty
        ? 'Unnamed $_typeLabel'
        : _nameController.text.trim();

    final previewIcon = switch (widget.type) {
      AdminCategoryType.segment => Icons.palette_outlined,
      AdminCategoryType.genre => Icons.category_outlined,
      AdminCategoryType.subGenre => Icons.account_tree_outlined,
    };

    final previewColor = widget.type == AdminCategoryType.segment
        ? _selectedColor
        : colorScheme.primary;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colors.border,
                ),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                      ),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _screenTitle,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _screenDescription,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.inputFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.borderSoft,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: previewColor.withValues(
                                alpha: 0.20,
                              ),
                              borderRadius:
                                  BorderRadius.circular(18),
                              border: Border.all(
                                color: colors.borderSoft,
                              ),
                            ),
                            child: Icon(
                              previewIcon,
                              color: previewColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  previewName,
                                  style: textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.type.titleLabel,
                                  style: textTheme.bodySmall
                                      ?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Current status: ${_isActive ? 'Active' : 'Inactive'}',
                                  style: textTheme.bodySmall
                                      ?.copyWith(
                                    color: _isActive
                                        ? colorScheme.primary
                                        : colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _CategoryField(
                      controller: _nameController,
                      label: 'Name',
                      hintText:
                          'Enter ${widget.type.buttonLabel} name',
                      prefixIcon:
                          Icons.drive_file_rename_outline_rounded,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (widget.type ==
                        AdminCategoryType.segment) ...[
                      const SizedBox(height: 18),
                      _ColorPickerField(
                        label: 'Color',
                        hexValue: _toHex(_selectedColor),
                        color: _selectedColor,
                        enabled: !_isSubmitting,
                        onTap: _pickColor,
                      ),
                    ],
                    if (widget.type ==
                        AdminCategoryType.genre) ...[
                      const SizedBox(height: 18),
                      _CategoryDropdownField<int>(
                        label: 'Segment',
                        value: _selectedSegmentId,
                        enabled: !_isSubmitting,
                        prefixIcon: Icons.layers_outlined,
                        items: widget.segments
                            .map(
                              (segment) => DropdownMenuItem<int>(
                                value: segment.segmentId,
                                child: Text(segment.name),
                              ),
                            )
                            .toList(),
                        onChanged: _handleSegmentChanged,
                      ),
                    ],
                    if (widget.type ==
                        AdminCategoryType.subGenre) ...[
                      const SizedBox(height: 18),
                      _CategoryDropdownField<int>(
                        label: 'Segment',
                        value: _selectedSegmentId,
                        enabled: !_isSubmitting,
                        prefixIcon: Icons.layers_outlined,
                        items: widget.segments
                            .map(
                              (segment) => DropdownMenuItem<int>(
                                value: segment.segmentId,
                                child: Text(segment.name),
                              ),
                            )
                            .toList(),
                        onChanged: _handleSegmentChanged,
                      ),
                      const SizedBox(height: 18),
                      _CategoryDropdownField<int>(
                        label: 'Genre',
                        value: _selectedGenreId,
                        enabled: !_isSubmitting &&
                            _availableGenres.isNotEmpty,
                        prefixIcon: Icons.category_outlined,
                        items: _availableGenres
                            .map(
                              (genre) => DropdownMenuItem<int>(
                                value: genre.genreId,
                                child: Text(genre.name),
                              ),
                            )
                            .toList(),
                        onChanged: _handleGenreChanged,
                      ),
                    ],
                    const SizedBox(height: 18),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                      title: Text(
                        'Active',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InformationPanel(
                      type: widget.type,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      colors: colors,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    colors.textSecondary,
                                side: BorderSide(
                                  color: colors.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    AppThemeMetrics.radiusMd + 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    colorScheme.primary,
                                foregroundColor:
                                    colorScheme.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    AppThemeMetrics.radiusMd + 2,
                                  ),
                                ),
                              ),
                              child: _isSubmitting
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<
                                                Color>(
                                          colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Save changes',
                                      style: textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight:
                                            FontWeight.w700,
                                        color:
                                            colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InformationPanel extends StatelessWidget {
  const _InformationPanel({
    required this.type,
    required this.colorScheme,
    required this.textTheme,
    required this.colors,
  });

  final AdminCategoryType type;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final message = switch (type) {
      AdminCategoryType.segment =>
        'Segments can include a custom color. Genres and subgenres inherit structure from parent categories and do not need a separate color.',
      AdminCategoryType.genre =>
        'Genres are grouped inside a segment. Make sure the selected segment matches your intended category structure.',
      AdminCategoryType.subGenre =>
        'Subgenres belong to a genre, which in turn belongs to a segment. Keep that hierarchy consistent before saving.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.borderSoft,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        AppThemeMetrics.radiusMd,
      ),
      borderSide: BorderSide(
        color: colors.borderSoft,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.inputFill,
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary.withValues(
                alpha: 0.72,
              ),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: colors.textSecondary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppThemeMetrics.radiusMd,
              ),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppThemeMetrics.radiusMd,
              ),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppThemeMetrics.radiusMd,
              ),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryDropdownField<T> extends StatelessWidget {
  const _CategoryDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.prefixIcon,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        AppThemeMetrics.radiusMd,
      ),
      borderSide: BorderSide(
        color: colors.borderSoft,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: (selectedValue) {
            if (selectedValue == null) {
              return '$label is required.';
            }

            return null;
          },
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.inputFill,
            prefixIcon: Icon(
              prefixIcon,
              color: colors.textSecondary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppThemeMetrics.radiusMd,
              ),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppThemeMetrics.radiusMd,
              ),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppThemeMetrics.radiusMd,
              ),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerField extends StatelessWidget {
  const _ColorPickerField({
    required this.label,
    required this.hexValue,
    required this.color,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final String hexValue;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.borderSoft,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.borderSoft,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        hexValue,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to choose a color from the wheel.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.color_lens_outlined,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}