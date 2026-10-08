import 'package:flutter/material.dart';

enum PasswordStrengthLevel { veryWeak, weak, medium, strong, veryStrong }

class PasswordStrength extends StatelessWidget {
  final String password;

  const PasswordStrength({super.key, required this.password});

  PasswordStrengthLevel get level {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    if (RegExp(r'[A-Z]').hasMatch(password)) score++;

    if (RegExp(r'[a-z]').hasMatch(password)) score++;

    if (RegExp(r'[0-9]').hasMatch(password)) score++;

    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 1) {
      return PasswordStrengthLevel.veryWeak;
    }

    if (score == 2) {
      return PasswordStrengthLevel.weak;
    }

    if (score == 3 || score == 4) {
      return PasswordStrengthLevel.medium;
    }

    if (score == 5) {
      return PasswordStrengthLevel.strong;
    }

    return PasswordStrengthLevel.veryStrong;
  }

  Color get color {
    switch (level) {
      case PasswordStrengthLevel.veryWeak:
        return Colors.red;

      case PasswordStrengthLevel.weak:
        return Colors.orange;

      case PasswordStrengthLevel.medium:
        return Colors.amber;

      case PasswordStrengthLevel.strong:
        return Colors.lightGreen;

      case PasswordStrengthLevel.veryStrong:
        return Colors.green;
    }
  }

  String get label {
    switch (level) {
      case PasswordStrengthLevel.veryWeak:
        return "Foarte slabă";

      case PasswordStrengthLevel.weak:
        return "Slabă";

      case PasswordStrengthLevel.medium:
        return "Medie";

      case PasswordStrengthLevel.strong:
        return "Puternică";

      case PasswordStrengthLevel.veryStrong:
        return "Foarte puternică";
    }
  }

  int get bars {
    switch (level) {
      case PasswordStrengthLevel.veryWeak:
        return 1;

      case PasswordStrengthLevel.weak:
        return 2;

      case PasswordStrengthLevel.medium:
        return 3;

      case PasswordStrengthLevel.strong:
        return 4;

      case PasswordStrengthLevel.veryStrong:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            5,
            (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 6,
                decoration: BoxDecoration(
                  color: index < bars
                      ? color
                      : Colors.grey.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _Requirement(ok: password.length >= 8, text: "Minimum 8 caractere"),
        _Requirement(
          ok: RegExp(r'[A-Z]').hasMatch(password),
          text: "O literă mare",
        ),
        _Requirement(
          ok: RegExp(r'[a-z]').hasMatch(password),
          text: "O literă mică",
        ),
        _Requirement(ok: RegExp(r'[0-9]').hasMatch(password), text: "O cifră"),
        _Requirement(
          ok: RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password),
          text: "Un caracter special",
        ),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  final bool ok;
  final String text;

  const _Requirement({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            color: ok ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
