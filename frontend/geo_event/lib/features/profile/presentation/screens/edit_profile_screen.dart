import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_bottom_sheet_container.dart';
import '../../../../core/widgets/app_spinner.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../shared/profile/models/user_profile.dart';
import '../../application/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final ImagePicker _imagePicker;

  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  XFile? _pickedImage;
  bool _removeCurrentPhoto = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _phoneController =
        TextEditingController(text: widget.profile.phoneNumber ?? '');
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

  String? _validateName(String? value, String label) {
    final text = (value ?? '').trim();

    if (text.isEmpty) return '$label is required';
    if (text.length < 2) return '$label must be at least 2 characters';
    if (text.length > 50) return '$label must be at most 50 characters';

    final regex = RegExp(r"^[A-Za-zÀ-ÿČĆĐŠŽčćđšž'\- ]+$");
    if (!regex.hasMatch(text)) {
      return '$label contains invalid characters';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;

    final normalized = text.replaceAll(RegExp(r'[\s\-()]'), '');
    final regex = RegExp(r'^\+?[0-9]{7,15}$');

    if (!regex.hasMatch(normalized)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _normalizePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return text.replaceAll(RegExp(r'[\s\-()]'), '');
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

      setState(() {
        _pickedImage = image;
        _removeCurrentPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image.')),
      );
    }
  }

  Future<void> _showImageSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final hasAnyPhoto =
            _pickedImage != null ||
            (widget.profile.imageUrl?.trim().isNotEmpty ?? false);

        return AppBottomSheetContainer(
          header: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile photo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              if (hasAnyPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Remove photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pickedImage = null;
                      _removeCurrentPhoto = true;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    String? finalImageUrl =
        _removeCurrentPhoto ? null : widget.profile.imageUrl;

    if (_pickedImage != null) {
      try {
        finalImageUrl = await ref
            .read(profileControllerProvider.notifier)
            .uploadProfileImage(_pickedImage!);
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile image.')),
        );
        return;
      }
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _normalizePhone(_phoneController.text),
          imageUrl: finalImageUrl,
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasNetworkImage =
        !_removeCurrentPhoto &&
        (widget.profile.imageUrl?.trim().isNotEmpty ?? false);

    final ImageProvider? avatarImage = _pickedImage != null
        ? FileImage(File(_pickedImage!.path))
        : (hasNetworkImage
            ? NetworkImage(widget.profile.imageUrl!.trim())
            : null);

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppSurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              widget.profile.fullName.isNotEmpty
                                  ? widget.profile.fullName[0].toUpperCase()
                                  : '?',
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profile.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _emailController.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color,
                            ),
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
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateName(value, 'First name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _validateName(value, 'Last name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                ),
                validator: _validatePhone,
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