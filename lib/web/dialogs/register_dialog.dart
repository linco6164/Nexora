import 'package:flutter/material.dart';

class RegisterDialog extends StatelessWidget {
  const RegisterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: const SizedBox(
        width: 500,
        height: 700,
        child: Center(
          child: Text(
            "Register",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}