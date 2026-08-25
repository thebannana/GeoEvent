import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_metrics.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/admin_profile/data/admin_users_repository.dart';
import '../../../../shared/admin_profile/models/user_profile.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({
    super.key,
    required this.profile,
    required this.repository,
  });

  final UserProfile profile;
  final AdminUsersRepository repository;

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  static const _loggerTag = 'EditUserScreen';

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

  bool _isSubmitting = false;
  bool _isUploadingAvatar = false;

  Uint8List? _selectedAvatarBytes;
  String? _selectedAvatarPath;
  String? _uploadedImageUrl;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController(
      text: widget.profile.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.profile.lastName,
    );
    _phoneController = TextEditingController(
      text: widget.profile.phoneNumber ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.profile.username,
    );
    _emailController = TextEditingController(
      text: widget.profile.email,
    );

    _uploadedImageUrl = widget.profile.imageUrl;
    _selectedRole = _normalizeRole(widget.profile.role);

    AppLogger.debug(
      'Edit-user screen initialized.',
      tag: _loggerTag,
    );
  }

  @override
  void dispose() {
    AppLogger.debug(
      'Edit-user screen disposed.',
      tag: _loggerTag,
    );

    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();

    if (normalized == AppRoles.admin.toLowerCase()) {
      return AppRoles.admin;
    }

    return AppRoles.user;
  }

  String? _validateOptionalPhone(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return null;
    }

    return Validators.phoneNumber(text);
  }

  String? _normalizeOptionalPhone(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return null;
    }

    return text.replaceAll(
      RegExp(r'[\s\-\(\)]'),
      '',
    );
  }

  Future<void> _pickAvatar() async {
    if (_isSubmitting || _isUploadingAvatar) {
      AppLogger.debug(
        'Avatar selection ignored because the screen is busy.',
        tag: _loggerTag,
      );
      return;
    }

    AppLogger.debug(
      'Avatar picker opened.',
      tag: _loggerTag,
    );

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: const [
          'png',
          'jpg',
          'jpeg',
          'webp',
        ],
      );

      if (!mounted || result == null || result.files.isEmpty) {
        AppLogger.debug(
          'Avatar selection was cancelled.',
          tag: _loggerTag,
        );
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      final path = file.path;

      if (bytes == null || bytes.isEmpty) {
        AppLogger.warning(
          'Selected avatar did not contain readable bytes.',
          tag: _loggerTag,
        );

        _showMessage(
          'Unable to read the selected image.',
        );
        return;
      }

      if (path == null || path.trim().isEmpty) {
        AppLogger.warning(
          'Selected avatar did not contain a valid file path.',
          tag: _loggerTag,
        );

        _showMessage(
          'Unable to access the selected image path.',
        );
        return;
      }

      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarPath = path;
      });

      AppLogger.info(
        'Avatar selected successfully.',
        tag: _loggerTag,
      );

      await _uploadSelectedAvatar();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Avatar picker failed.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        'Unable to select the avatar.',
      );
    }
  }

  Future<void> _uploadSelectedAvatar() async {
    final filePath = _selectedAvatarPath;

    if (filePath == null || filePath.trim().isEmpty) {
      AppLogger.warning(
        'Avatar upload skipped because the file path was empty.',
        tag: _loggerTag,
      );
      return;
    }

    if (_isUploadingAvatar) {
      AppLogger.debug(
        'Duplicate avatar upload ignored.',
        tag: _loggerTag,
      );
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });

    AppLogger.info(
      'Avatar upload started.',
      tag: _loggerTag,
    );

    try {
      final imageUrl = await widget.repository.uploadProfileImage(
        filePath,
      );

      if (!mounted) return;

      final normalizedImageUrl = imageUrl.trim();

      if (normalizedImageUrl.isEmpty) {
        AppLogger.warning(
          'Avatar upload returned an empty image URL.',
          tag: _loggerTag,
        );

        _showMessage(
          'Avatar upload did not return a valid image URL.',
        );
        return;
      }

      setState(() {
        _uploadedImageUrl = normalizedImageUrl;
      });

      AppLogger.info(
        'Avatar upload completed successfully.',
        tag: _loggerTag,
      );

      _showMessage(
        'Avatar uploaded successfully.',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Avatar upload failed.',
        tag: _loggerTag,
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      _showMessage(
        'Failed to upload avatar.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }

      AppLogger.debug(
        'Avatar upload state reset.',
        tag: _loggerTag,
      );
    }
  }

  Future<void> _submit() async {
  if (_isSubmitting) {
    AppLogger.debug(
      'Duplicate user-update action ignored.',
      tag: _loggerTag,
    );
    return;
  }

  if (_isUploadingAvatar) {
    AppLogger.debug(
      'User update ignored while avatar upload is active.',
      tag: _loggerTag,
    );
    return;
  }

  final form = _formKey.currentState;

  if (form == null) {
    AppLogger.warning(
      'Edit-user form state was unavailable.',
      tag: _loggerTag,
    );
    return;
  }

  FocusScope.of(context).unfocus();

  if (!form.validate()) {
    AppLogger.debug(
      'Edit-user form validation failed.',
      tag: _loggerTag,
    );
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  AppLogger.info(
    'User update started.',
    tag: _loggerTag,
  );

  try {
    final updatedUser = await widget.repository.updateUser(
      userId: widget.profile.userId,
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _normalizeOptionalPhone(
        _phoneController.text,
      ),
      imageUrl: _uploadedImageUrl,
      role: _selectedRole,
    );

    if (!mounted) return;

    AppLogger.info(
      'User update completed successfully.',
      tag: _loggerTag,
    );

    _showMessage(
      'User updated successfully.',
    );

    context.pop(updatedUser);
  } catch (error, stackTrace) {
    AppLogger.error(
      'User update failed.',
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
            'Could not update this user. Please try again.',
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }

    AppLogger.debug(
      'User-update state reset.',
      tag: _loggerTag,
    );
  }
}

  void _goBack() {
    if (_isSubmitting || _isUploadingAvatar) {
      return;
    }

    AppLogger.debug(
      'User returned from edit-user screen.',
      tag: _loggerTag,
    );

    context.pop();
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
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final displayName = [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');

    final username = _usernameController.text.trim();

    final avatarLetter = displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : username.isNotEmpty
            ? username.characters.first.toUpperCase()
            : 'U';

    final imageUrl = _uploadedImageUrl?.trim();
    final hasRemoteAvatar =
        imageUrl != null && imageUrl.isNotEmpty;

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
                      onPressed: _isSubmitting ||
                              _isUploadingAvatar
                          ? null
                          : _goBack,
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
                      'Edit User',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Update account information, avatar, and role for this user.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: colors.inputFill,
                          backgroundImage:
                              _selectedAvatarBytes != null
                                  ? MemoryImage(
                                      _selectedAvatarBytes!,
                                    )
                                  : hasRemoteAvatar
                                      ? NetworkImage(imageUrl)
                                      : null,
                          child: _selectedAvatarBytes == null &&
                                  !hasRemoteAvatar
                              ? Text(
                                  avatarLetter,
                                  style: textTheme.titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName.isEmpty
                                    ? 'Unnamed user'
                                    : displayName,
                                style: textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _emailController.text.trim(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Current status: ${widget.profile.isBanned ? 'Banned' : 'Active'}',
                                style: textTheme.bodySmall
                                    ?.copyWith(
                                  color: widget.profile.isBanned
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _isSubmitting ||
                                            _isUploadingAvatar
                                        ? null
                                        : _pickAvatar,
                                    icon: _isUploadingAvatar
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                colorScheme.primary,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .photo_camera_back_outlined,
                                          ),
                                    label: Text(
                                      _isUploadingAvatar
                                          ? 'Uploading...'
                                          : 'Change avatar',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          colorScheme.primary,
                                      side: BorderSide(
                                        color: colors.border,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          AppThemeMetrics.radiusMd,
                                        ),
                                      ),
                                    ),
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
                      children: [
                        Expanded(
                          child: _EditUserField(
                            controller: _firstNameController,
                            label: 'First name',
                            hintText: 'Enter first name',
                            prefixIcon: Icons.badge_outlined,
                            enabled: !_isSubmitting,
                            textInputAction:
                                TextInputAction.next,
                            validator: Validators.firstName,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _EditUserField(
                            controller: _lastNameController,
                            label: 'Last name',
                            hintText: 'Enter last name',
                            prefixIcon: Icons.badge_outlined,
                            enabled: !_isSubmitting,
                            textInputAction:
                                TextInputAction.next,
                            validator: Validators.lastName,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _EditUserField(
                      controller: _usernameController,
                      label: 'Username',
                      hintText: 'Enter username',
                      prefixIcon:
                          Icons.alternate_email_rounded,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      validator: Validators.username,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    _EditUserField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'Enter email',
                      prefixIcon: Icons.mail_outline_rounded,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      keyboardType:
                          TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    _EditUserField(
                      controller: _phoneController,
                      label: 'Phone number',
                      hintText: 'Enter phone number',
                      prefixIcon: Icons.call_outlined,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      validator: _validateOptionalPhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    _RoleDropdownField(
                      label: 'Role',
                      initialValue: _selectedRole,
                      enabled: !_isSubmitting,
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedRole = value;
                        });

                        AppLogger.debug(
                          'User role changed.',
                          tag: _loggerTag,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This screen updates user identity fields and role. Ban and unban actions can remain in the users table workflow.',
                              style: textTheme.bodyMedium
                                  ?.copyWith(
                                fontSize: 14,
                                height: 1.5,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isSubmitting ||
                                      _isUploadingAvatar
                                  ? null
                                  : _goBack,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    colors.textSecondary,
                                side: BorderSide(
                                  color: colors.border,
                                ),
                                shape:
                                    RoundedRectangleBorder(
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
                              onPressed: _isSubmitting ||
                                      _isUploadingAvatar
                                  ? null
                                  : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    colorScheme.primary,
                                foregroundColor:
                                    colorScheme.onPrimary,
                                elevation: 0,
                                shape:
                                    RoundedRectangleBorder(
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

class _EditUserField extends StatelessWidget {
  const _EditUserField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
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
          keyboardType: keyboardType,
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

class _RoleDropdownField extends StatelessWidget {
  const _RoleDropdownField({
    required this.label,
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String initialValue;
  final bool enabled;
  final ValueChanged<String?> onChanged;

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
        DropdownButtonFormField<String>(
          initialValue: initialValue,
          isExpanded: true,
          onChanged: enabled ? onChanged : null,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Role is required.';
            }

            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.inputFill,
            prefixIcon: Icon(
              Icons.verified_user_outlined,
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
          items: [
            DropdownMenuItem<String>(
              value: AppRoles.user,
              child: Text(AppRoles.user),
            ),
            DropdownMenuItem<String>(
              value: AppRoles.admin,
              child: Text(AppRoles.admin),
            ),
          ],
        ),
      ],
    );
  }
}