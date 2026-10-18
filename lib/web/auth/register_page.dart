import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';

import '../../api_service.dart';
import '../../app_feedback.dart';
import 'login_page.dart';
import '../legal/privacy_page.dart';
import '../legal/terms_page.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/password_strength.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  String? get _referralCode {
    final value = Uri.base.queryParameters['ref']?.trim().toUpperCase();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      AppFeedback.warning(
        context,
        'Trebuie să accepți termenii și condițiile.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await ApiService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        referralCode: _referralCode,
      );

      if (!mounted) return;

      AppFeedback.success(context, 'Contul a fost creat. Te poți autentifica.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;

      AppFeedback.error(context, e, fallback: 'Contul nu a putut fi creat.');
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: appLocaleController.value == 'en'
                        ? 'Create an account'
                        : 'Creează un cont',
                    subtitle: appLocaleController.value == 'en'
                        ? 'Join Nexora and start buying or selling.'
                        : 'Alătură-te Nexora și începe să cumperi sau să vinzi.',
                  ),

                  if (_referralCode != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer
                            .withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              appLocaleController.value == 'en'
                                  ? 'Invitation applied: $_referralCode'
                                  : 'Invitație aplicată: $_referralCode',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (username.length < 3) {
                        return appLocaleController.value == 'en'
                            ? 'Enter at least 3 characters'
                            : 'Introdu minimum 3 caractere';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: appLocaleController.value == 'en'
                          ? 'Username'
                          : 'Nume de utilizator',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  AuthTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return appLocaleController.value == 'en'
                            ? 'The password must have at least 8 characters'
                            : 'Parola trebuie să aibă minimum 8 caractere';
                      }

                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: appLocaleController.value == 'en'
                          ? 'Password'
                          : 'Parolă',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  PasswordStrength(password: _passwordController.text),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return appLocaleController.value == 'en'
                            ? 'Passwords do not match'
                            : 'Parolele nu coincid';
                      }

                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: appLocaleController.value == 'en'
                          ? 'Confirm password'
                          : 'Confirmă parola',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  CheckboxListTile(
                    value: _acceptTerms,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    title: Wrap(
                      children: [
                        Text(
                          appLocaleController.value == 'en'
                              ? 'I accept '
                              : 'Accept ',
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TermsPage(),
                              ),
                            );
                          },
                          child: Text(
                            appLocaleController.value == 'en'
                                ? 'Terms and conditions'
                                : 'Termenii și condițiile',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          appLocaleController.value == 'en' ? ' and ' : ' și ',
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPage(),
                              ),
                            );
                          },
                          child: Text(
                            appLocaleController.value == 'en'
                                ? 'Privacy policy'
                                : 'Politica de confidențialitate',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text('.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            appLocaleController.value == 'en'
                                ? 'Create account'
                                : 'Creează contul',
                          ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appLocaleController.value == 'en'
                            ? 'Already have an account?'
                            : 'Ai deja un cont?',
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: Text(context.tr('Autentificare')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
