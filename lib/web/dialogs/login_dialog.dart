import 'package:flutter/material.dart';

import '../auth/login_page.dart';

class LoginDialog extends StatelessWidget {
  const LoginDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const SizedBox(
        width: 560,
        height: 720,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          child: LoginPage(),
        ),
      ),
    );
  }
}
