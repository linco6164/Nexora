import 'package:flutter/material.dart';

import 'api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {
  final _formKey =
      GlobalKey<FormState>();

  final _currentPasswordController =
      TextEditingController();

  final _newPasswordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Introdu parola.';
    }

    if (value.length < 8) {
      return 'Parola trebuie să aibă cel puțin 8 caractere.';
    }

    return null;
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text !=
        _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Parolele noi nu coincid.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.changePassword(
        currentPassword:
            _currentPasswordController.text,
        newPassword:
            _newPasswordController.text,
      );

      if (!mounted) return;

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Parola a fost schimbată cu succes.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _decoration(
    String label,
    bool hidden,
    VoidCallback onToggle,
  ) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .primary,
          width: 2,
        ),
      ),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          hidden
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schimbă parola',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schimbă parola contului',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Folosește o parolă puternică și nu o reutiliza pe alte site-uri.',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 28),

                TextFormField(
                  controller:
                      _currentPasswordController,
                  obscureText: _hideCurrent,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Introdu parola actuală.';
                    }

                    return null;
                  },
                  decoration: _decoration(
                    'Parola actuală',
                    _hideCurrent,
                    () {
                      setState(() {
                        _hideCurrent =
                            !_hideCurrent;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _newPasswordController,
                  obscureText: _hideNew,
                  validator:
                      _validatePassword,
                  decoration: _decoration(
                    'Parolă nouă',
                    _hideNew,
                    () {
                      setState(() {
                        _hideNew =
                            !_hideNew;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _confirmPasswordController,
                  obscureText: _hideConfirm,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Confirmă parola nouă.';
                    }

                    if (value !=
                        _newPasswordController
                            .text) {
                      return 'Parolele nu coincid.';
                    }

                    return null;
                  },
                  decoration: _decoration(
                    'Confirmă parola nouă',
                    _hideConfirm,
                    () {
                      setState(() {
                        _hideConfirm =
                            !_hideConfirm;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                _PasswordRequirements(
                  password:
                      _newPasswordController
                          .text,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        _isSaving
                            ? null
                            : _changePassword,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Schimbă parola',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirements
    extends StatelessWidget {
  final String password;

  const _PasswordRequirements({
    required this.password,
  });

  Widget _item(
    String text,
    bool valid,
  ) {
    return Row(
      children: [
        Icon(
          valid
              ? Icons.check_circle
              : Icons.circle_outlined,
          size: 17,
          color:
              valid ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: valid
                ? Colors.green
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLength =
        password.length >= 8;

    final hasUpper =
        RegExp(r'[A-Z]').hasMatch(password);

    final hasLower =
        RegExp(r'[a-z]').hasMatch(password);

    final hasNumber =
        RegExp(r'[0-9]').hasMatch(password);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Cerințe parolă',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _item(
          'Cel puțin 8 caractere',
          hasLength,
        ),
        _item(
          'O literă mare',
          hasUpper,
        ),
        _item(
          'O literă mică',
          hasLower,
        ),
        _item(
          'O cifră',
          hasNumber,
        ),
      ],
    );
  }
}