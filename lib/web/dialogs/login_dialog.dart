import 'package:flutter/material.dart';

import '../auth/login_page.dart';

class LoginDialog extends StatelessWidget {
  const LoginDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const SizedBox(
        width: 480,
        height: 660,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          child: LoginPage(),
        ),
      ),
    );
  }
}
