import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/layout/app_bottom_sheet_container.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/profile/models/user_profile.dart';
import '../../application/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final ImagePicker _imagePicker;

  bool _isSubmitting = false;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _removeCurrentPhoto = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _phoneController = TextEditingController(
      text: widget.profile.phoneNumber ?? '',
    );
    _usernameController = TextEditingController(text: widget.profile.username);
    _emailController = TextEditingController(text: widget.profile.email);
    _imagePicker = ImagePicker();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      final bytes = kIsWeb ? await image.readAsBytes() : null;

      setState(() {
        _pickedImage = image;
        _pickedImageBytes = bytes;
        _removeCurrentPhoto = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not pick image.',
        ),
      );
    }
  }

  Future<void> _showImageSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final hasCurrentPhoto =
            !_removeCurrentPhoto &&
            (widget.profile.imageUrl?.trim().isNotEmpty ?? false);
        final hasAnyPhoto = _pickedImage != null || hasCurrentPhoto;

        return AppBottomSheetContainer(
          header: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile photo',
                    style: Theme.of(bottomSheetContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                enabled: !_isSubmitting,
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                enabled: !_isSubmitting,
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              if (hasAnyPhoto)
                ListTile(
                  enabled: !_isSubmitting,
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Remove photo'),
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();
                    await _confirmRemovePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemovePhoto() async {
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove photo'),
            content: const Text(
              'Are you sure you want to remove your profile photo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldRemove || !mounted) return;

    setState(() {
      _pickedImage = null;
      _pickedImageBytes = null;
      _removeCurrentPhoto = true;
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isSubmitting) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      String? finalImageUrl =
          _removeCurrentPhoto ? null : widget.profile.imageUrl?.trim();

      if (_pickedImage != null) {
        finalImageUrl = await ref
            .read(profileControllerProvider.notifier)
            .uploadProfileImage(_pickedImage!);
      }

      final success = await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phoneNumber: _normalizeOptionalPhone(_phoneController.text),
            imageUrl: finalImageUrl,
          );

      if (!mounted) return;

      if (!success) {
        _showMessage('Failed to update profile.');
        return;
      }

      _showMessage('Profile updated successfully.');
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.toMessage(
          error,
          stackTrace: stackTrace,
          fallbackMessage: AppStrings.genericError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateOptionalPhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return Validators.phoneNumber(text);
  }

  String? _validateUsername(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Username is required.';
    }

    if (text.length < 3 || text.length > 30) {
      return 'Username must be between 3 and 30 characters.';
    }

    final valid = RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(text);
    if (!valid) {
      return 'Username can contain only letters, numbers, dots, and underscores.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Email is required.';
    }

    return Validators.email(text);
  }

  String? _normalizeOptionalPhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return text.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasNetworkImage =
        !_removeCurrentPhoto &&
        (widget.profile.imageUrl?.trim().isNotEmpty ?? false);

    final ImageProvider? avatarImage = _pickedImage != null
        ? (kIsWeb
            ? MemoryImage(_pickedImageBytes!)
            : FileImage(File(_pickedImage!.path)) as ImageProvider)
        : (hasNetworkImage
            ? NetworkImage(widget.profile.imageUrl!.trim())
            : null);

    final displayName = [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');

    final avatarLetter =
        displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : '?';

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: avatarImage,
                      child: avatarImage == null ? Text(avatarLetter) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isEmpty ? 'Unnamed user' : displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _emailController.text.trim(),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed:
                                _isSubmitting ? null : _showImageSourcePicker,
                            icon: const Icon(Icons.photo_camera_back_outlined),
                            label: Text(
                              _pickedImage != null
                                  ? 'Change selected photo'
                                  : 'Change photo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'First name',
                ),
                validator: Validators.firstName,
                textInputAction: TextInputAction.next,
                enabled: !_isSubmitting,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                ),
                validator: Validators.lastName,
                textInputAction: TextInputAction.next,
                enabled: !_isSubmitting,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                validator: _validateUsername,
                textInputAction: TextInputAction.next,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
                enabled: !_isSubmitting,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                ),
                validator: _validateOptionalPhone,
                textInputAction: TextInputAction.done,
                enabled: !_isSubmitting,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const AppSpinner(
                        size: 18,
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}