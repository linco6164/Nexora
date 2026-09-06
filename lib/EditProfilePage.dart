import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  String? _avatarUrl;
  File? _newAvatar;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();

      if (!mounted) return;

      setState(() {
        _usernameController.text = profile['username'] ?? '';
        _fullNameController.text = profile['fullName'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _countryController.text = profile['country'] ?? '';
        _cityController.text = profile['city'] ?? '';
        _countyController.text = profile['county'] ?? '';
        _postalCodeController.text = profile['postalCode'] ?? '';
        _instagramController.text = profile['instagram'] ?? '';
        _facebookController.text = profile['facebook'] ?? '';
        _websiteController.text = profile['website'] ?? '';

        _avatarUrl = profile['avatar'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nu am putut încărca profilul: $e'),
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null) return;

    setState(() {
      _newAvatar = File(image.path);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _avatarUrl;

      // Upload avatar nou
      if (_newAvatar != null) {
        setState(() => _isUploadingAvatar = true);

        final urls = await ApiService.uploadImages(
          [_newAvatar!],
          folder: 'avatars',
        );

        if (urls.isNotEmpty) {
          avatarUrl = urls.first;
        }

        if (mounted) {
          setState(() => _isUploadingAvatar = false);
        }
      }

      final updatedProfile = await ApiService.updateProfile(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        avatar: avatarUrl,
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        county: _countyController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        instagram: _instagramController.text.trim(),
        facebook: _facebookController.text.trim(),
        website: _websiteController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilul a fost actualizat'),
        ),
      );

      Navigator.pop(context, updatedProfile);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingAvatar = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingAvatar = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _postalCodeController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _websiteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editează profilul'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _buildAvatarSection(),

                  const SizedBox(height: 32),

                  _buildSectionTitle('Informații personale'),

                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Nume complet',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _usernameController,
                    label: 'Nume utilizator',
                    icon: Icons.alternate_email,
                    prefixText: '@',
                    validator: (value) {
                      final username = value?.trim() ?? '';

                      if (username.isEmpty) {
                        return 'Introdu numele de utilizator';
                      }

                      if (username.length < 3) {
                        return 'Minimum 3 caractere';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _bioController,
                    label: 'Descriere',
                    icon: Icons.notes_outlined,
                    maxLines: 4,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 28),

                  _buildSectionTitle('Locație'),

                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _countryController,
                    label: 'Țară',
                    icon: Icons.public_outlined,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _countyController,
                    label: 'Județ',
                    icon: Icons.map_outlined,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _cityController,
                    label: 'Oraș',
                    icon: Icons.location_city_outlined,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _postalCodeController,
                    label: 'Cod poștal',
                    icon: Icons.markunread_mailbox_outlined,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 28),

                  _buildSectionTitle('Rețele sociale'),

                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _instagramController,
                    label: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _facebookController,
                    label: 'Facebook',
                    icon: Icons.facebook_outlined,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _websiteController,
                    label: 'Website',
                    icon: Icons.language_outlined,
                    keyboardType: TextInputType.url,
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Salvează modificările',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),

          Stack(
            children: [
              CircleAvatar(
                radius: 58,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: _newAvatar != null
                    ? FileImage(_newAvatar!)
                    : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? NetworkImage(_avatarUrl!)
                        : null),
                child: (_newAvatar == null &&
                        (_avatarUrl == null || _avatarUrl!.isEmpty))
                    ? const Icon(
                        Icons.person,
                        size: 58,
                      )
                    : null,
              ),

              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _isUploadingAvatar ? null : _pickAvatar,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _isUploadingAvatar
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt_outlined,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: _isUploadingAvatar ? null : _pickAvatar,
            child: const Text('Schimbă fotografia'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}