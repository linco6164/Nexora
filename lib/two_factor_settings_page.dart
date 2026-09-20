import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';

class TwoFactorSettingsPage extends StatefulWidget {
  const TwoFactorSettingsPage({super.key});

  @override
  State<TwoFactorSettingsPage> createState() => _TwoFactorSettingsPageState();
}

class _TwoFactorSettingsPageState extends State<TwoFactorSettingsPage> {
  bool _isLoading = true;
  bool _isSetup = false;

  String? _qrCode;
  String? _secret;

  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ============================================================
  // VERIFICĂ STAREA 2FA
  // ============================================================

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final enabled = await ApiService.get2FAStatus();

      if (!mounted) return;

      setState(() {
        _isSetup = enabled;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la verificarea stării 2FA: $e')),
      );
    }
  }

  // ============================================================
  // PORNEȘTE CONFIGURAREA 2FA
  // ============================================================

  Future<void> _startSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.setup2FA();

      if (!mounted) return;

      setState(() {
        _qrCode = data['qrCode']?.toString() ?? data['qr']?.toString();

        _secret = data['secret']?.toString();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare la configurarea 2FA: $e')));
    }
  }

  // ============================================================
  // CONFIRMĂ ACTIVAREA 2FA
  // ============================================================

  Future<void> _verifySetup() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codul trebuie să aibă 6 cifre.')),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final recoveryCodes = await ApiService.verify2FASetup(tokenCode: code);

      if (!mounted) return;

      setState(() {
        _isSetup = true;
        _isLoading = false;
        _codeController.clear();
      });

      await _showRecoveryCodes(recoveryCodes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autentificarea în doi pași a fost activată.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Eroare la activarea 2FA: $e')));
    }
  }

  // ============================================================
  // CODURI DE RECUPERARE
  // ============================================================

  Future<void> _showRecoveryCodes(List<String> codes) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Coduri de recuperare'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salvează aceste coduri într-un loc sigur. Le poți folosi dacă nu mai ai acces la aplicația de autentificare.',
                ),

                const SizedBox(height: 20),

                ...codes.map(
                  (code) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Am salvat codurile'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DEZACTIVEAZĂ 2FA
  // ============================================================

  Future<void> _disable2FA() async {
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Dezactivează 2FA'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pentru dezactivarea autentificării în doi pași, introdu codul actual din aplicația de autentificare.',
              ),

              const SizedBox(height: 20),

              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 22, letterSpacing: 6),
                decoration: const InputDecoration(
                  labelText: 'Cod 2FA',
                  hintText: '000000',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Anulează'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.length != 6) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Codul trebuie să aibă 6 cifre.'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Dezactivează'),
            ),
          ],
        );
      },
    );

    if (code == null || code.length != 6) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.disable2FA(tokenCode: code);

      if (!mounted) return;

      setState(() {
        _isSetup = false;
        _isLoading = false;
        _qrCode = null;
        _secret = null;
        _codeController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autentificarea în doi pași a fost dezactivată.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Eroare la dezactivarea 2FA: $e')));
    }
  }

  // ============================================================
  // QR CODE
  // ============================================================

  Widget _buildQrCode() {
    if (_qrCode == null) {
      return const SizedBox.shrink();
    }

    try {
      final base64String = _qrCode!.contains(',')
          ? _qrCode!.split(',').last
          : _qrCode!;

      return Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Image.memory(
            base64Decode(base64String),
            width: 220,
            height: 220,
          ),
        ),
      );
    } catch (_) {
      return SelectableText(_qrCode!);
    }
  }

  // ============================================================
  // PAGINA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Autentificare în doi pași')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Autentificare în doi pași')),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ======================================================
          // ICON
          // ======================================================

          Icon(
            _isSetup ? Icons.verified_user_rounded : Icons.security_rounded,
            size: 72,
            color: _isSetup
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 20),

          // ======================================================
          // TITLU
          // ======================================================
          Text(
            _isSetup ? '2FA este activat' : 'Protejează-ți contul',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // DESCRIERE
          // ======================================================
          Text(
            _isSetup
                ? 'La fiecare autentificare vei avea nevoie și de codul generat de aplicația de autentificare.'
                : 'Folosește o aplicație precum Google Authenticator, Microsoft Authenticator sau Authy pentru a genera codurile de securitate.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),

          const SizedBox(height: 30),

          // ======================================================
          // 2FA ACTIVAT
          // ======================================================
          if (_isSetup) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 28,
                  ),

                  SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Autentificarea în doi pași este activată',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'Contul tău este protejat suplimentar atunci când te autentifici.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // DEZACTIVEAZĂ
            // ====================================================
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _disable2FA,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text(
                  'Dezactivează 2FA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],

          // ======================================================
          // 2FA NEACTIVAT
          // ======================================================
          if (!_isSetup && _qrCode == null) ...[
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _startSetup,
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Configurează 2FA'),
              ),
            ),
          ],

          // ======================================================
          // CONFIGURARE QR
          // ======================================================
          if (!_isSetup && _qrCode != null) ...[
            const Text(
              '1. Scanează codul QR',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 16),

            _buildQrCode(),

            if (_secret != null) ...[
              const SizedBox(height: 20),

              const Text(
                'Dacă nu poți scana codul QR, introdu manual cheia:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _secret!,
                        style: const TextStyle(
                          fontSize: 15,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    IconButton(
                      tooltip: 'Copiază cheia',
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _secret!));

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cheia secretă a fost copiată.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            const Text(
              '2. Introdu codul generat',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
                hintText: '000000',
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _verifySetup,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Activează 2FA'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
