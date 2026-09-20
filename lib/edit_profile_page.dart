import 'package:flutter/material.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  late final TextEditingController _countyController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late final TextEditingController _websiteController;

  bool _isSaving = false;

  // Telefonul devine blocat după ce există deja un număr.
  bool _phoneLocked = false;

  bool _emailLocked = false;

  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedAvatar;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();

    _avatarUrl = widget.user['avatar']?.toString();

    _usernameController = TextEditingController(
      text: widget.user['username']?.toString() ?? '',
    );

    _fullNameController = TextEditingController(
      text: widget.user['fullName']?.toString() ?? '',
    );

    final existingPhone = widget.user['phone']?.toString().trim() ?? '';

    final existingEmail = widget.user['email']?.toString().trim() ?? '';

    _emailController = TextEditingController(text: existingEmail);

    _emailLocked = existingEmail.isNotEmpty;

    _phoneController = TextEditingController(text: existingPhone);

    // Dacă există deja un număr, câmpul este blocat.
    _phoneLocked = existingPhone.isNotEmpty;

    _bioController = TextEditingController(
      text: widget.user['bio']?.toString() ?? '',
    );

    _countryController = TextEditingController(
      text: widget.user['country']?.toString() ?? '',
    );

    _cityController = TextEditingController(
      text: widget.user['city']?.toString() ?? '',
    );

    _countyController = TextEditingController(
      text: widget.user['county']?.toString() ?? '',
    );

    _postalCodeController = TextEditingController(
      text: widget.user['postalCode']?.toString() ?? '',
    );

    _instagramController = TextEditingController(
      text: widget.user['instagram']?.toString() ?? '',
    );

    _facebookController = TextEditingController(
      text: widget.user['facebook']?.toString() ?? '',
    );

    _websiteController = TextEditingController(
      text: widget.user['website']?.toString() ?? '',
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) return;

      setState(() {
        _selectedAvatar = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu s-a putut selecta imaginea: $e')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
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

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_selectedAvatar != null) {
        setState(() {
          _isUploadingAvatar = true;
        });

        try {
          final urls = await ApiService.uploadImages([
            _selectedAvatar!,
          ], folder: 'avatars');

          if (urls.isNotEmpty) {
            _avatarUrl = urls.first;
          }
        } finally {
          if (mounted) {
            setState(() {
              _isUploadingAvatar = false;
            });
          }
        }
      }

      final updatedProfile = await ApiService.updateProfile(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),

        // Telefonul este trimis doar la prima adăugare.
        phone: _phoneController.text.trim(),

        bio: _bioController.text.trim(),
        avatar: _avatarUrl,
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        county: _countyController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        instagram: _instagramController.text.trim(),
        facebook: _facebookController.text.trim(),
        website: _websiteController.text.trim(),
      );

      if (!mounted) return;

      if (_emailController.text.trim().isNotEmpty) {
        setState(() {
          _emailLocked = true;
        });
      }

      // După prima salvare, dacă există număr,
      // îl blocăm definitiv în Edit Profile.
      if (_phoneController.text.trim().isNotEmpty) {
        setState(() {
          _phoneLocked = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilul a fost actualizat.')),
      );

      Navigator.pop(context, updatedProfile);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _decoration({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim()
        : 'Utilizator';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editează profilul'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Salvează',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // AVATAR
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    backgroundImage: _selectedAvatar != null
                        ? FileImage(_selectedAvatar!)
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? NetworkImage(_avatarUrl!)
                              : null),
                    child:
                        _selectedAvatar == null &&
                            (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  GestureDetector(
                    onTap: _isUploadingAvatar ? null : _pickAvatar,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 3,
                        ),
                      ),
                      child: _isUploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(7),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 17,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // DATE PERSONALE
            const Text(
              'DATE PERSONALE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.6,
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'Nume utilizator',
                icon: Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Introdu numele de utilizator';
                }

                if (value.trim().length < 3) {
                  return 'Minim 3 caractere';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'Nume complet',
                icon: Icons.badge_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _emailController,
              readOnly: _emailLocked,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration:
                  _decoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ).copyWith(
                    suffixIcon: _emailLocked
                        ? const Icon(Icons.lock_outline)
                        : null,
                    filled: _emailLocked,
                    fillColor: _emailLocked
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : null,
                  ),
            ),

            if (_emailLocked) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Pentru schimbarea emailului accesează Securitate → Email.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // TELEFON
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,

              // După prima adăugare devine blocat.
              readOnly: _phoneLocked,

              decoration:
                  _decoration(
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                  ).copyWith(
                    suffixIcon: _phoneLocked
                        ? const Icon(Icons.lock_outline)
                        : null,
                    filled: _phoneLocked,
                    fillColor: _phoneLocked
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : null,
                  ),
            ),

            if (_phoneLocked) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Pentru schimbarea numărului accesează Securitate → Număr de telefon.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],

            const SizedBox(height: 14),

            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 300,
              decoration: _decoration(
                label: 'Descriere',
                icon: Icons.description_outlined,
                hint: 'Spune ceva despre tine',
              ),
            ),

            const SizedBox(height: 20),

            // LOCAȚIE
            const Text(
              'LOCAȚIE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.6,
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _countryController,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'Țară',
                icon: Icons.public_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _countyController,
              textInputAction: TextInputAction.next,
              decoration: _decoration(label: 'Județ', icon: Icons.map_outlined),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _cityController,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'Oraș',
                icon: Icons.location_city_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _postalCodeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'Cod poștal',
                icon: Icons.markunread_mailbox_outlined,
              ),
            ),

            const SizedBox(height: 20),

            // SOCIAL
            const Text(
              'LINKURI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.6,
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _instagramController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'Instagram',
                icon: Icons.camera_alt_outlined,
                hint: 'https://instagram.com/...',
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _facebookController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                label: 'Facebook',
                icon: Icons.facebook_outlined,
                hint: 'https://facebook.com/...',
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: _decoration(
                label: 'Website',
                icon: Icons.language_outlined,
                hint: 'https://...',
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salvează modificările',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
