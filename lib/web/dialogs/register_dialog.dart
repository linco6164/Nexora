import 'package:flutter/material.dart';

import '../auth/register_page.dart';

class RegisterDialog extends StatelessWidget {
  const RegisterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const SizedBox(
        width: 560,
        height: 820,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          child: RegisterPage(),
        ),
      ),
    );
  }
}
