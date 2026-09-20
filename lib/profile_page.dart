import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'login_page.dart';
import 'theme_settings_page.dart';
import 'notification_settings_page.dart';
import 'socket_service.dart';
import 'sold_page.dart';
import 'support_page.dart';
import 'edit_profile_page.dart';
import 'addresses_page.dart';
import 'security_page.dart';
import 'api_service.dart';

class ProfilePage extends StatefulWidget {
  final ValueChanged<bool>? onNavBarCollapse;

  const ProfilePage({super.key, this.onNavBarCollapse});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggingOut = false;
  bool _isLoadingUser = true;

  Map<String, dynamic>? _user;

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
      final user = await ApiService.getCurrentUser();

      debugPrint('PROFILE: USER PRIMIT = $user');

      if (!mounted) return;

      setState(() {
        _user = Map<String, dynamic>.from(user);
        _isLoadingUser = false;
      });

      debugPrint('PROFILE: setState făcut');
      debugPrint('PROFILE: username = ${_user?['username']}');
      debugPrint('PROFILE: avatar = ${_user?['avatar']}');
      debugPrint('PROFILE: email = ${_user?['email']}');
    } catch (e, stackTrace) {
      debugPrint('PROFILE ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
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
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final email = _user?['email']?.toString() ?? 'Necunoscut';

    final fullName = _user?['username']?.toString() ?? 'Utilizator';

    final avatarValue = _user?['avatar']?.toString();

    final avatarUrl = avatarValue != null && avatarValue.isNotEmpty
        ? avatarValue
        : null;

    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), centerTitle: false),

      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadUser,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.only(top: 24, bottom: 100),

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
                          radius: 52,
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
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),

                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 14),

                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: Colors.amber,
                        ),

                        const SizedBox(width: 4),

                        const Text(
                          '0.0',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          '(0 evaluări)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(user: _user!),
                          ),
                        );

                        if (result != null && mounted) {
                          setState(() {
                            _user = Map<String, dynamic>.from(
                              result['user'] ?? result,
                            );
                          });
                        }
                      },
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _ProfileStat(value: '0', label: 'Anunțuri'),
                      ),

                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.grey.withValues(alpha: 0.25),
                      ),

                      const Expanded(
                        child: _ProfileStat(value: '0', label: 'Vânzări'),
                      ),

                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.grey.withValues(alpha: 0.25),
                      ),

                      const Expanded(
                        child: _ProfileStat(value: '0', label: 'Evaluări'),
                      ),
                    ],
                  ),
                ),
              ),

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
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Adrese salvate'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressesPage()),
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
                    MaterialPageRoute(builder: (_) => const SecurityPage()),
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
                    MaterialPageRoute(builder: (_) => const SupportPage()),
                  );
                },
              ),

              const Divider(),

              const SizedBox(height: 16),

              // ─────────────────────────────
              // LOGOUT
              // ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _isLoggingOut ? null : _showLogoutConfirmation,
                  icon: _isLoggingOut
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
