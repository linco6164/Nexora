import 'package:flutter/material.dart';
import '../api_service.dart';

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({
    super.key,
    required this.phone,
    required this.phoneVerified,
  });

  final String? phone;
  final bool phoneVerified;

  @override
  State<PhoneVerificationPage> createState() =>
      _PhoneVerificationPageState();
}

class _PhoneVerificationPageState
    extends State<PhoneVerificationPage> {
  late bool _phoneVerified;
  late String? _phone;

  bool _sending = false;
  bool _loading = false;
  bool _changingPhone = false;
  bool _codeSent = false;

  String? _error;
  String? _success;

  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _phoneVerified = widget.phoneVerified;
    _phone = widget.phone;

    _phoneController.text = widget.phone ?? '';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      _error = null;
      _success = null;
    });
  }

  Future<void> _sendVerificationCode() async {
    _clearMessages();

    setState(() {
      _sending = true;
    });

    try {
      await ApiService.sendPhoneVerification();

      if (!mounted) return;

      setState(() {
        _codeSent = true;
        _success =
            'Codul de verificare a fost trimis prin SMS.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _verifyPhone() async {
    _clearMessages();

    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _error = 'Introdu un cod format din 6 cifre.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await ApiService.verifyPhone(code: code);

      if (!mounted) return;

      setState(() {
        _phoneVerified = true;
        _codeSent = false;
        _codeController.clear();
        _success =
            'Numărul de telefon a fost verificat cu succes.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _requestPhoneChange() async {
    _clearMessages();

    final newPhone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (newPhone.isEmpty) {
      setState(() {
        _error = 'Introdu noul număr de telefon.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _error = 'Introdu parola actuală.';
      });
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await ApiService.requestPhoneChange(
        newPhone: newPhone,
        currentPassword: password,
      );

      if (!mounted) return;

      setState(() {
        _codeSent = true;
        _success =
            'Codul pentru schimbarea numărului a fost trimis prin SMS.';
        _passwordController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _confirmPhoneChange() async {
    _clearMessages();

    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _error = 'Introdu un cod format din 6 cifre.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await ApiService.confirmPhoneChange(
        code: code,
      );

      if (!mounted) return;

      setState(() {
        _phoneVerified = true;
        _phone = _phoneController.text.trim();
        _changingPhone = false;
        _codeSent = false;

        _codeController.clear();

        _success =
            'Numărul de telefon a fost schimbat și verificat.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _startPhoneChange() {
    _clearMessages();

    setState(() {
      _changingPhone = true;
      _codeSent = false;
      _codeController.clear();
      _passwordController.clear();
      _phoneController.text = _phone ?? '';
    });
  }

  void _cancelPhoneChange() {
    _clearMessages();

    setState(() {
      _changingPhone = false;
      _codeSent = false;
      _codeController.clear();
      _passwordController.clear();
      _phoneController.text = _phone ?? '';
    });
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefon'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),

              if (_error != null) ...[
                _buildMessage(
                  _error!,
                  isError: true,
                ),
                const SizedBox(height: 16),
              ],

              if (_success != null) ...[
                _buildMessage(
                  _success!,
                  isError: false,
                ),
                const SizedBox(height: 16),
              ],

              if (!_phoneVerified && !_changingPhone)
                _buildVerificationSection(theme),

              if (_phoneVerified && !_changingPhone)
                _buildVerifiedSection(theme),

              if (_changingPhone)
                _buildChangeSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.phone_outlined,
            size: 34,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Număr de telefon',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _phone == null || _phone!.isEmpty
              ? 'Nu ai un număr de telefon adăugat.'
              : _phone!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerificationSection(ThemeData theme) {
    if (_phone == null || _phone!.isEmpty) {
      return _buildEmptyPhoneSection(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard(
          icon: Icons.verified_user_outlined,
          title: 'Număr neverificat',
          text:
              'Verifică numărul de telefon pentru a confirma că îți aparține.',
        ),

        const SizedBox(height: 24),

        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          enabled: !_loading,
          decoration: const InputDecoration(
            labelText: 'Cod de verificare',
            hintText: '123456',
            prefixIcon: Icon(Icons.password_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 8),

        if (!_codeSent)
          FilledButton.icon(
            onPressed:
                _sending ? null : _sendVerificationCode,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sms_outlined),
            label: Text(
              _sending
                  ? 'Se trimite...'
                  : 'Trimite codul',
            ),
          ),

        if (_codeSent) ...[
          FilledButton.icon(
            onPressed:
                _loading ? null : _verifyPhone,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.verified_outlined),
            label: Text(
              _loading
                  ? 'Se verifică...'
                  : 'Verifică telefonul',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed:
                _sending ? null : _sendVerificationCode,
            child: const Text('Trimite din nou codul'),
          ),
        ],
      ],
    );
  }

  Widget _buildVerifiedSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard(
          icon: Icons.verified,
          title: 'Telefon verificat',
          text:
              'Numărul tău de telefon este verificat și asociat contului.',
        ),

        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: _startPhoneChange,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifică numărul de telefon'),
        ),
      ],
    );
  }

  Widget _buildChangeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard(
          icon: Icons.edit_outlined,
          title: 'Modifică numărul',
          text:
              'Introdu noul număr și parola actuală. Vom trimite un cod SMS către noul număr.',
        ),

        const SizedBox(height: 24),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          enabled: !_codeSent && !_sending,
          decoration: const InputDecoration(
            labelText: 'Număr nou',
            hintText: '07xxxxxxxx',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        if (!_codeSent) ...[
          TextField(
            controller: _passwordController,
            obscureText: true,
            enabled: !_sending,
            decoration: const InputDecoration(
              labelText: 'Parola actuală',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed:
                _sending ? null : _requestPhoneChange,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sms_outlined),
            label: Text(
              _sending
                  ? 'Se trimite...'
                  : 'Trimite codul',
            ),
          ),
        ],

        if (_codeSent) ...[
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Cod SMS',
              hintText: '123456',
              prefixIcon: Icon(Icons.password_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          FilledButton.icon(
            onPressed:
                _loading ? null : _confirmPhoneChange,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _loading
                  ? 'Se confirmă...'
                  : 'Confirmă schimbarea',
            ),
          ),
        ],

        const SizedBox(height: 10),

        OutlinedButton(
          onPressed:
              _sending || _loading
                  ? null
                  : _cancelPhoneChange,
          child: const Text('Anulează'),
        ),
      ],
    );
  }

  Widget _buildEmptyPhoneSection(ThemeData theme) {
    return _buildInfoCard(
      icon: Icons.phone_disabled_outlined,
      title: 'Număr de telefon lipsă',
      text:
          'Adaugă mai întâi un număr de telefon în profilul tău.',
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
    String message, {
    required bool isError,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline
                : Icons.check_circle_outline,
            color: isError
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}