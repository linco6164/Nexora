import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';

import 'package:provider/provider.dart';

import '../../api_service.dart';
import '../../app_feedback.dart';
import '../../forgotten_password.dart';
import '../../notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/facebook_web_auth.dart';
import '../../socket_service.dart';
import '../../two_factor_page.dart';
import '../web_shell.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/social_login_buttons.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['requiresTwoFactor'] == true) {
        final userId = result['userId']?.toString() ?? '';
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TwoFactorPage(
              userId: userId,
              successPage: const WebShell(),
              onVerified: context.read<AuthProvider>().loadUser,
            ),
          ),
        );
        return;
      }

      await _completeLogin();
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.loadUser();

    if (!auth.isLoggedIn) {
      throw ApiException(
        'Sesiunea a fost creată, dar profilul nu a putut fi încărcat.',
      );
    }

    try {
      await NotificationService.instance.registerCurrentTokenWithBackend();
    } catch (error) {
      debugPrint('[WEB LOGIN] Notificările nu au fost conectate: $error');
    }

    try {
      await SocketService.connect();
    } catch (error) {
      debugPrint('[WEB LOGIN] Socket-ul nu a fost conectat: $error');
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WebShell()),
      (route) => false,
    );
  }

  Future<void> _googleLogin(String idToken) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await ApiService.googleLogin(idToken);
      await _completeLogin();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _facebookLogin() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final accessToken = await requestFacebookAccessToken();
      await ApiService.facebookLogin(accessToken);
      await _completeLogin();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    AppFeedback.error(
      context,
      error is ApiException ? error.message : error,
      fallback: 'Autentificarea nu a putut fi finalizată.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 520 ? 12 : 24,
          ),
          child: AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: appLocaleController.value == 'en'
                        ? 'Welcome back'
                        : 'Bine ai revenit',
                    subtitle: appLocaleController.value == 'en'
                        ? 'Sign in to continue to Nexora.'
                        : 'Autentifică-te pentru a continua în Nexora.',
                  ),

                  const SizedBox(height: 32),

                  AuthTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocaleController.value == 'en'
                            ? 'Enter your password'
                            : 'Introdu parola';
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

                  const SizedBox(height: 16),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          Text(
                            appLocaleController.value == 'en'
                                ? 'Remember me'
                                : 'Ține-mă minte',
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgottenPassword(),
                            ),
                          );
                        },
                        child: Text(
                          appLocaleController.value == 'en'
                              ? 'Forgot password?'
                              : 'Ai uitat parola?',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('Autentificare')),
                  ),

                  const SizedBox(height: 24),

                  const AuthDivider(),

                  const SizedBox(height: 24),

                  SocialLoginButtons(
                    loading: _loading,
                    onGoogleCredential: _googleLogin,
                    onGoogleError: _showError,
                    onFacebook: _facebookLogin,
                  ),

                  const SizedBox(height: 24),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        appLocaleController.value == 'en'
                            ? "Don't have an account?"
                            : 'Nu ai cont?',
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          appLocaleController.value == 'en'
                              ? 'Register'
                              : 'Înregistrează-te',
                        ),
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
