import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_page.dart';
import 'theme_settings_page.dart';
import 'notification_settings_page.dart';
import 'socket_service.dart';
import 'sold_page.dart';
import 'support_page.dart';
import 'edit_profile_page.dart';
import 'addresses_page.dart';
import 'security_page.dart';
import 'my_listings_page.dart';
import 'my_reviews_page.dart';
import 'selling_orders_page.dart';
import 'promotion_page.dart';
import 'api_service.dart';
import 'saved_cards_page.dart';
import 'invite_friend_page.dart';
import 'legal/legal_center_page.dart';
import 'providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  final ValueChanged<bool>? onNavBarCollapse;
  final ValueChanged<String>? onNavigate;
  final bool embedded;
  final Future<void> Function()? onLogout;

  const ProfilePage({
    super.key,
    this.onNavBarCollapse,
    this.onNavigate,
    this.embedded = false,
    this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggingOut = false;
  bool _isLoadingUser = true;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _stats;
  String? _loadError;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleProfileScroll);

    _loadUser();
  }

  Future<void> _loadUser() async {
    debugPrint('PROFILE: începe încărcarea userului');

    try {
      final result = await ApiService.getProfile();

      debugPrint('PROFILE: RĂSPUNS API = $result');

      if (!mounted) return;

      setState(() {
        _user = result['user'] is Map
            ? Map<String, dynamic>.from(result['user'])
            : Map<String, dynamic>.from(result);

        _stats = result['stats'] is Map
            ? Map<String, dynamic>.from(result['stats'])
            : <String, dynamic>{};

        _isLoadingUser = false;
        _loadError = null;
      });

      debugPrint('PROFILE: user = $_user');
      debugPrint('PROFILE: stats = $_stats');
    } catch (e, stackTrace) {
      debugPrint('PROFILE ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
        _loadError = e is ApiException
            ? e.message
            : 'Profilul nu a putut fi încărcat.';
      });
    }
  }

  void _handleProfileScroll() {
    if (!_scrollController.hasClients) return;

    final direction = _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse) {
      widget.onNavBarCollapse?.call(true);
    } else if (direction == ScrollDirection.forward) {
      widget.onNavBarCollapse?.call(false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      SocketService.disconnect();

      if (widget.onLogout != null) {
        await widget.onLogout!();
        return;
      }

      await ApiService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare la delogare: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _openEditProfile() async {
    final user = _user;
    if (user == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
    );

    if (result == null || !mounted) return;

    final updated = result is Map && result['user'] is Map
        ? Map<String, dynamic>.from(result['user'])
        : Map<String, dynamic>.from(result as Map);

    setState(() => _user = updated);
    await context.read<AuthProvider>().loadUser();
  }

  void _openDestination(String destination, Widget page) {
    if (widget.embedded && widget.onNavigate != null) {
      widget.onNavigate!(destination);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Uri? _profileLink(String value, {String? profileBase}) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;

    final direct = Uri.tryParse(cleaned);
    if (direct != null &&
        (direct.scheme == 'https' || direct.scheme == 'http')) {
      return direct;
    }

    if (cleaned.contains('.') || cleaned.contains('/')) {
      return Uri.tryParse('https://$cleaned');
    }

    if (profileBase != null) {
      final username = cleaned.replaceFirst(RegExp(r'^@'), '');
      return Uri.tryParse('$profileBase/${Uri.encodeComponent(username)}');
    }

    return Uri.tryParse('https://$cleaned');
  }

  Future<void> _openProfileLink(String value, {String? profileBase}) async {
    final uri = _profileLink(value, profileBase: profileBase);
    if (uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Linkul nu a putut fi deschis.')),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deconectare'),
        content: const Text('Sigur vrei să te deconectezi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            child: const Text(
              'Deconectare',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleProfileScroll);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Profil'),
              ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null || _user == null) {
      return Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Profil'),
              ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined, size: 54),
                const SizedBox(height: 14),
                Text(
                  _loadError ?? 'Profil indisponibil.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _isLoadingUser = true);
                    _loadUser();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reîncearcă'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final email = _user?['email']?.toString() ?? 'Necunoscut';

    final username = _user?['username']?.toString() ?? 'Utilizator';
    final fullNameValue = _user?['fullName']?.toString().trim() ?? '';
    final fullName = fullNameValue.isNotEmpty ? fullNameValue : username;
    final bio = _user?['bio']?.toString().trim() ?? '';
    final city = _user?['city']?.toString().trim() ?? '';
    final county = _user?['county']?.toString().trim() ?? '';
    final phone = _user?['phone']?.toString().trim() ?? '';
    final instagram = _user?['instagram']?.toString().trim() ?? '';
    final facebook = _user?['facebook']?.toString().trim() ?? '';
    final website = _user?['website']?.toString().trim() ?? '';
    final verified = _user?['verified'] == true;
    final location = [city, county].where((part) => part.isNotEmpty).join(', ');

    final avatarValue = _user?['avatar']?.toString();

    final avatarUrl = avatarValue != null && avatarValue.isNotEmpty
        ? avatarValue
        : null;

    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Profil'),
              centerTitle: false,
            ),

      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadUser,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.embedded ? 820 : 900,
              ),
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),

                padding: EdgeInsets.only(
                  top: widget.embedded ? 20 : 24,
                  bottom: widget.embedded ? 48 : 100,
                ),

                children: [
                  // ─────────────────────────────
                  // PROFIL
                  // ─────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: widget.embedded ? 42 : 52,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Text(
                                      fullName.isNotEmpty
                                          ? fullName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: widget.embedded ? 30 : 38,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),

                            Material(
                              color: primary,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _openEditProfile,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                fullName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (verified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                size: 20,
                                color: Colors.blue,
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '@$username',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),

                        if (location.isNotEmpty || phone.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              if (location.isNotEmpty)
                                _ProfileDetail(
                                  icon: Icons.location_on_outlined,
                                  value: location,
                                ),
                              if (phone.isNotEmpty)
                                _ProfileDetail(
                                  icon: Icons.phone_outlined,
                                  value: phone,
                                ),
                            ],
                          ),
                        ],

                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Text(
                              bio,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(height: 1.5),
                            ),
                          ),
                        ],

                        if (instagram.isNotEmpty ||
                            facebook.isNotEmpty ||
                            website.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (instagram.isNotEmpty)
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Instagram'),
                                  onPressed: () => _openProfileLink(
                                    instagram,
                                    profileBase: 'https://instagram.com',
                                  ),
                                ),
                              if (facebook.isNotEmpty)
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.facebook_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Facebook'),
                                  onPressed: () => _openProfileLink(
                                    facebook,
                                    profileBase: 'https://facebook.com',
                                  ),
                                ),
                              if (website.isNotEmpty)
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.language_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Website'),
                                  onPressed: () => _openProfileLink(website),
                                ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (((_stats?['rating'] ?? 0) as num?) ?? 0)
                                  .toDouble()
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed: _openEditProfile,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editează profilul'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─────────────────────────────
                  // STATISTICI
                  // ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ProfileStat(
                              value: '${_stats?['listings'] ?? 0}',
                              label: 'Anunțuri',
                              onTap: () => _openDestination(
                                'listings',
                                const MyListingsPage(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _ProfileStat(
                              value: '${_stats?['sold'] ?? 0}',
                              label: 'Vânzări',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SellingOrdersPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _ProfileStat(
                              value: '${_stats?['reviews'] ?? 0}',
                              label: 'Evaluări',
                              onTap: () => _openDestination(
                                'reviews',
                                const MyReviewsPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _InviteProfileCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InviteFriendPage(),
                        ),
                      ),
                    ),
                  ),

                  if (widget.embedded)
                    const SizedBox(height: 36)
                  else ...[
                    const SizedBox(height: 24),

                    const Divider(),

                    // ─────────────────────────────
                    // CONT
                    // ─────────────────────────────
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'CONT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.wallet_outlined),
                      title: const Text('Sold'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SoldPage()),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.sell_outlined),
                      title: const Text('Vânzările mele'),
                      subtitle: const Text('Comenzi primite și expediere'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SellingOrdersPage(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.rocket_launch_outlined),
                      title: const Text('Instrumente promotionale'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PromotionPage(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Adrese salvate'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressesPage(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.credit_card_outlined),
                      title: const Text('Cardurile mele'),
                      subtitle: const Text('Metode de plată salvate'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedCardsPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // ─────────────────────────────
                    // SETĂRI
                    // ─────────────────────────────
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'SETĂRI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: const Text('Securitate'),
                      subtitle: const Text('Parolă, 2FA și dispozitive'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SecurityPage(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notificări'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Temă aplicație'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ThemeSettingsPage(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Ajutor și suport'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupportPage(),
                          ),
                        );
                      },
                    ),

                    if (!kIsWeb) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'JURIDIC',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.gavel_outlined),
                        title: const Text('Informații juridice'),
                        subtitle: const Text(
                          'Termeni, confidențialitate, livrare și retur',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalCenterPage(),
                            ),
                          );
                        },
                      ),
                    ],

                    const Divider(),

                    const SizedBox(height: 16),

                    // ─────────────────────────────
                    // LOGOUT
                    // ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton.icon(
                        onPressed: _isLoggingOut
                            ? null
                            : _showLogoutConfirmation,
                        icon: _isLoggingOut
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Deconectare',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _InviteProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primaryContainer.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.group_add_rounded, color: colors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invită un prieten',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Câștigați amândoi câte 100 RON',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ProfileDetail({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 5),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _ProfileStat({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
