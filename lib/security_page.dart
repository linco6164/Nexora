import 'package:flutter/material.dart';

import '../api_service.dart';
import 'change_password_page.dart';
import 'two_factor_settings_page.dart';
import 'session_page.dart';
import 'email_verification_page.dart';
import 'phone_verification_page.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  String? _phone;
  bool _phoneVerified = false;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile();

      if (!mounted) return;

      final user = data['user'];

      setState(() {
        _phone = user?['phone']?.toString();
        _phoneVerified = user?['phoneVerified'] == true;
        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingProfile = false;
      });
    }
  }

  Future<void> _openPhoneVerification() async {
    if (_loadingProfile) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneVerificationPage(
          phone: _phone,
          phoneVerified: _phoneVerified,
        ),
      ),
    );

    // Reîncărcăm profilul când revenim
    // pentru a avea statusul actualizat.
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Securitate'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SecuritySectionTitle(
            title: 'Cont',
          ),

          _SecurityTile(
            icon: Icons.lock_outline,
            title: 'Schimbă parola',
            subtitle: 'Actualizează parola contului tău',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          const _SecuritySectionTitle(
            title: 'Autentificare',
          ),

          _SecurityTile(
            icon: Icons.verified_user_outlined,
            title: 'Autentificare în doi pași',
            subtitle:
                'Protejează contul cu un cod suplimentar',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const TwoFactorSettingsPage(),
                ),
              );
            },
          ),

          _SecurityTile(
            icon: Icons.devices_outlined,
            title: 'Sesiuni și dispozitive',
            subtitle:
                'Vezi unde este conectat contul tău',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SessionsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          const _SecuritySectionTitle(
            title: 'Verificări',
          ),

          _SecurityTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle:
                'Verifică adresa de email a contului',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const EmailVerificationPage(),
                ),
              );
            },
          ),

          _SecurityTile(
            icon: Icons.phone_outlined,
            title: 'Număr de telefon',
            subtitle: _loadingProfile
                ? 'Se încarcă...'
                : _phoneVerified
                    ? 'Număr verificat'
                    : _phone == null || _phone!.isEmpty
                        ? 'Adaugă un număr de telefon'
                        : 'Verifică numărul de telefon',
            onTap: _openPhoneVerification,
          ),

          const SizedBox(height: 24),

          const _SecuritySectionTitle(
            title: 'Cont',
          ),

          _SecurityTile(
            icon: Icons.delete_outline,
            title: 'Șterge contul',
            subtitle:
                'Șterge permanent contul și datele',
            danger: true,
            onTap: () {
              // Urmează implementarea ștergerii contului
            },
          ),
        ],
      ),
    );
  }
}

class _SecuritySectionTitle extends StatelessWidget {
  final String title;

  const _SecuritySectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Colors.red
        : Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: danger ? Colors.red : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}