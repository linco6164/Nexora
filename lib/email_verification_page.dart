import 'package:flutter/material.dart';
import '../api_service.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState
    extends State<EmailVerificationPage> {
  final TextEditingController _codeController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _checkingStatus = true;
  bool _emailVerified = false;

  bool _sending = false;
  bool _loading = false;

  bool _changingEmail = false;
  bool _codeSent = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final verified =
          await ApiService.getEmailVerificationStatus();

      if (!mounted) return;

      setState(() {
        _emailVerified = verified;
        _checkingStatus = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingStatus = false;
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ApiService.sendEmailVerification();

      if (!mounted) return;

      setState(() {
        _codeSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Codul a fost trimis pe adresa ta de email.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _verifyEmail() async {
    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _error = 'Introdu un cod format din 6 cifre.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.verifyEmail(
        code: code,
      );

      if (!mounted) return;

      setState(() {
        _emailVerified = true;
        _codeSent = false;
        _codeController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adresa de email a fost verificată.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _requestEmailChange() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() {
        _error = 'Introdu noua adresă de email.';
      });
      return;
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email)) {
      setState(() {
        _error = 'Introdu o adresă de email validă.';
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
      _error = null;
    });

    try {
      await ApiService.requestEmailChange(
        newEmail: email,
        currentPassword: password,
      );

      if (!mounted) return;

      setState(() {
        _codeSent = true;
        _passwordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Codul a fost trimis pe noua adresă de email.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _confirmEmailChange() async {
    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _error = 'Introdu un cod format din 6 cifre.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.confirmEmailChange(
        code: code,
      );

      if (!mounted) return;

      setState(() {
        _changingEmail = false;
        _codeSent = false;
        _codeController.clear();
        _emailController.clear();
        _emailVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adresa de email a fost schimbată cu succes.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _startEmailChange() {
    setState(() {
      _changingEmail = true;
      _codeSent = false;
      _error = null;
    });
  }

  void _cancelEmailChange() {
    setState(() {
      _changingEmail = false;
      _codeSent = false;
      _error = null;

      _codeController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _emailVerified
              ? _buildVerifiedView()
              : _buildVerificationView(),
        ),
      ),
    );
  }

  Widget _buildVerificationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Icon(
          Icons.mark_email_unread_outlined,
          size: 64,
        ),

        const SizedBox(height: 24),

        const Text(
          'Verifică adresa de email',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Verifică adresa de email pentru a securiza contul și pentru a putea recupera accesul.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 28),

        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            labelText: 'Cod de verificare',
            hintText: '123456',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),

        const SizedBox(height: 16),

        _buildError(),

        if (!_codeSent)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _sending ? null : _sendVerificationCode,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Trimite codul',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _loading ? null : _verifyEmail,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Verifică emailul',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed:
                  _sending ? null : _sendVerificationCode,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Trimite din nou codul',
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerifiedView() {
    if (_changingEmail) {
      return _buildEmailChangeView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Icon(
          Icons.verified_rounded,
          size: 68,
        ),

        const SizedBox(height: 24),

        const Text(
          'Email verificat',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Adresa ta de email este verificată și poate fi folosită pentru securizarea contului.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        _buildError(),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _startEmailChange,
            icon: const Icon(
              Icons.edit_outlined,
            ),
            label: const Text(
              'Modifică adresa de email',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailChangeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Icon(
          Icons.alternate_email_rounded,
          size: 64,
        ),

        const SizedBox(height: 24),

        const Text(
          'Modifică adresa de email',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          _codeSent
              ? 'Introdu codul primit pe noua adresă de email.'
              : 'Introdu noua adresă de email și parola actuală. Vom trimite un cod pe noua adresă.',
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 28),

        if (!_codeSent) ...[
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Noua adresă de email',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Parola actuală',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          _buildError(),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _sending ? null : _requestEmailChange,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Trimite codul',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ] else ...[
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: 'Cod de verificare',
              hintText: '123456',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),

          const SizedBox(height: 20),

          _buildError(),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _loading ? null : _confirmEmailChange,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirmă schimbarea',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _cancelEmailChange,
              child: const Text(
                'Anulează',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError() {
    if (_error == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _error!,
        style: const TextStyle(
          color: Colors.red,
        ),
      ),
    );
  }
}