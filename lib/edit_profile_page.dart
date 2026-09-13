import 'package:flutter/material.dart';
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
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _countyController = TextEditingController();
  final _postalCodeController = TextEditingController();

  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String? _avatarUrl;
  String? _provider;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService.getProfile();

      Map<String, dynamic> user;

      if (result['data'] is Map &&
          result['data']['user'] is Map) {
        user = Map<String, dynamic>.from(
          result['data']['user'],
        );
      } else if (result['user'] is Map) {
        user = Map<String, dynamic>.from(
          result['user'],
        );
      } else {
        user = Map<String, dynamic>.from(result);
      }

      if (!mounted) return;

      setState(() {
        _usernameController.text =
            user['username']?.toString() ?? '';

        _fullNameController.text =
            user['fullName']?.toString() ?? '';

        _bioController.text =
            user['bio']?.toString() ?? '';

        _phoneController.text =
            user['phone']?.toString() ?? '';

        _cityController.text =
            user['city']?.toString() ?? '';

        _countryController.text =
            user['country']?.toString() ?? '';

        _countyController.text =
            user['county']?.toString() ?? '';

        _postalCodeController.text =
            user['postalCode']?.toString() ?? '';

        _websiteController.text =
            user['website']?.toString() ?? '';

        _instagramController.text =
            user['instagram']?.toString() ?? '';

        _facebookController.text =
            user['facebook']?.toString() ?? '';

        _avatarUrl = user['avatar']?.toString();
        _provider = user['provider']?.toString();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('EDIT PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nu am putut încărca profilul: $e',
          ),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.updateProfile(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        county: _countyController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        website: _websiteController.text.trim(),
        instagram: _instagramController.text.trim(),
        facebook: _facebookController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilul a fost actualizat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('EDIT PROFILE UPDATE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Eroare la salvarea profilului: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 21,
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecoration(
          label: label,
          icon: icon,
          hint: hint,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        right: 4,
        bottom: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader() {
    final theme = Theme.of(context);

    final username =
        _usernameController.text.trim();

    final initial = username.isNotEmpty
        ? username[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 26),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 43,
                backgroundColor:
                    theme.colorScheme.primaryContainer,
                backgroundImage:
                    _avatarUrl != null &&
                            _avatarUrl!.isNotEmpty
                        ? NetworkImage(_avatarUrl!)
                        : null,
                child:
                    _avatarUrl == null ||
                            _avatarUrl!.isEmpty
                        ? Text(
                            initial,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight:
                                  FontWeight.w800,
                              color: theme.colorScheme
                                  .onPrimaryContainer,
                            ),
                          )
                        : null,
              ),

              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  username.isNotEmpty
                      ? username
                      : 'Profilul tău',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Actualizează informațiile profilului',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
                if (_provider != null &&
                    _provider!.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Cont ${_provider!}',
                      style: TextStyle(
                        color:
                            theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editează profilul'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editează profilul',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          children: [
            _profileHeader(),

            // INFORMAȚII PERSONALE
            _sectionTitle(
              'Informații personale',
              'Datele principale ale profilului tău',
              Icons.person_outline_rounded,
            ),

            _field(
              label: 'Nume utilizator',
              icon: Icons.alternate_email_rounded,
              controller: _usernameController,
              hint: 'Ex. radu_emanuel',
            ),

            _field(
              label: 'Nume complet',
              icon: Icons.badge_outlined,
              controller: _fullNameController,
              hint: 'Ex. Radu Emanuel',
            ),

            _field(
              label: 'Despre tine',
              icon: Icons.notes_rounded,
              controller: _bioController,
              hint: 'Spune câteva lucruri despre tine...',
              maxLines: 4,
            ),

            _field(
              label: 'Număr de telefon',
              icon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 12),

            // LOCAȚIE
            _sectionTitle(
              'Locație',
              'Informații despre locația ta',
              Icons.location_on_outlined,
            ),

            _field(
              label: 'Țară',
              icon: Icons.public_rounded,
              controller: _countryController,
            ),

            _field(
              label: 'Județ',
              icon: Icons.map_outlined,
              controller: _countyController,
            ),

            _field(
              label: 'Oraș',
              icon: Icons.location_city_outlined,
              controller: _cityController,
            ),

            _field(
              label: 'Cod poștal',
              icon: Icons.markunread_mailbox_outlined,
              controller: _postalCodeController,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            // SOCIAL & WEB
            _sectionTitle(
              'Social & Web',
              'Linkurile și conturile tale',
              Icons.link_rounded,
            ),

            _field(
              label: 'Website',
              icon: Icons.language_rounded,
              controller: _websiteController,
              keyboardType: TextInputType.url,
              hint: 'https://...',
            ),

            _field(
              label: 'Instagram',
              icon: Icons.camera_alt_outlined,
              controller: _instagramController,
              hint: '@username',
            ),

            _field(
              label: 'Facebook',
              icon: Icons.facebook_rounded,
              controller: _facebookController,
            ),

            const SizedBox(height: 14),

            // SAVE
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(17),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration:
                      const Duration(milliseconds: 200),
                  child: _isSaving
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 23,
                          height: 23,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          key: ValueKey('save'),
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Salvează modificările',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                'Modificările vor fi salvate pe contul tău.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();

    _cityController.dispose();
    _countryController.dispose();
    _countyController.dispose();
    _postalCodeController.dispose();

    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();

    super.dispose();
  }
}