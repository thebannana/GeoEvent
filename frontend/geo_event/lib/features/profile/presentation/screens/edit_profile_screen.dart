import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import '../../../../shared/profile/models/user_profile.dart';

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
  late final TextEditingController _imageUrlController;
  late final TextEditingController _citySearchController;

  final _formKey = GlobalKey<FormState>();

  List<CitySearchResult> _cityResults = [];
  CitySearchResult? _selectedCity;
  Timer? _debounce;
  bool _isSubmitting = false;
  bool _isSearchingCity = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber ?? '');
    _imageUrlController = TextEditingController(text: widget.profile.imageUrl ?? '');
    _citySearchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  Future<void> _searchCities(String term) async {
    if (term.trim().length < 2) {
      setState(() {
        _cityResults = [];
        _isSearchingCity = false;
      });
      return;
    }

    setState(() => _isSearchingCity = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final results = await repo.searchCities(term, limit: 8);

      if (!mounted) return;
      setState(() {
        _cityResults = results;
        _isSearchingCity = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cityResults = [];
        _isSearchingCity = false;
      });
    }
  }

  void _onCityChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchCities(value);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(profileControllerProvider.notifier).updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          cityId: _selectedCity?.cityId ?? widget.profile.cityId,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.profile.username,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.profile.email,
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Profile image URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _citySearchController,
                onChanged: _onCityChanged,
                decoration: InputDecoration(
                  labelText: 'Search city',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearchingCity
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ),
              if (_selectedCity != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected city: ${_selectedCity!.displayLabel}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (_cityResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: _cityResults.map((city) {
                      return ListTile(
                        title: Text(city.cityName),
                        subtitle: Text(city.displayLabel),
                        onTap: () {
                          setState(() {
                            _selectedCity = city;
                            _citySearchController.text = city.displayLabel;
                            _cityResults = [];
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
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