import 'package:flutter/material.dart';

import '../auth/register_page.dart';

class RegisterDialog extends StatelessWidget {
  const RegisterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const SizedBox(
        width: 480,
        height: 740,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          child: RegisterPage(),
        ),
      ),
    );
  }
}
