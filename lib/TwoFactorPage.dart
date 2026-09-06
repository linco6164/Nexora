import 'package:flutter/material.dart';

import 'api_service.dart';
import 'HomePage.dart';
import 'socket_service.dart';
import 'NotificationService.dart';

class TwoFactorPage extends StatefulWidget {
  final String userId;

  const TwoFactorPage({super.key, required this.userId});

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
  if (_codeController.text.trim().length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Codul trebuie să aibă 6 cifre')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    await ApiService.verify2FA(
      userId: widget.userId,
      token: _codeController.text.trim(),
    );

    // JWT-ul este acum salvat.
    // Asociem tokenul FCM cu utilizatorul autentificat.
    final fcmToken =
        await NotificationService.instance.getToken();

    if (fcmToken != null && fcmToken.isNotEmpty) {
      await NotificationService.instance
          .registerTokenWithBackend(fcmToken);
    }

    await SocketService.connect();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
      (route) => false,
    );
  } on ApiException catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificare în 2 pași')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  'Introdu codul din aplicația de autentificare',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verifică'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
