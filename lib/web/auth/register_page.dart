import 'package:flutter/material.dart';

import '../../api_service.dart';
import 'login_page.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/password_strength.dart';
import 'widgets/social_login_buttons.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must accept Terms & Conditions."),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await ApiService.register(
        username: _emailController.text.split('@')[0],
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Account created successfully.",
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
          ),
        ),
      );
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
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: "Create Account",
                    subtitle:
                        "Join Nexora and start buying or selling today.",
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
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null ||
                          value.length < 8) {
                        return "Minimum 8 characters";
                      }

                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  PasswordStrength(
                    password:
                        _passwordController.text,
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller:
                        _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    validator: (value) {
                      if (value !=
                          _passwordController.text) {
                        return "Passwords do not match";
                      }

                      return null;
                    },
                    decoration: InputDecoration(
                      labelText:
                          "Confirm Password",
                      prefixIcon:
                          const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirm =
                                !_obscureConfirm;
                          });
                        },
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  CheckboxListTile(
                    value: _acceptTerms,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms =
                            value ?? false;
                      });
                    },
                    title: const Text(
                      "I accept the Terms & Conditions and Privacy Policy.",
                    ),
                  ),

                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed:
                        _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Create Account",
                          ),
                  ),

                  const SizedBox(height: 24),

                  const AuthDivider(),

                  const SizedBox(height: 24),

                  const SocialLoginButtons(),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LoginPage(),
                            ),
                          );
                        },
                        child: const Text("Login"),
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