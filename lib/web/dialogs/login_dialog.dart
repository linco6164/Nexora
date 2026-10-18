import 'package:flutter/material.dart';

import '../auth/login_page.dart';

class LoginDialog extends StatelessWidget {
  const LoginDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = (viewport.width - 24).clamp(0.0, 480.0).toDouble();
    final dialogHeight = (viewport.height - 24).clamp(0.0, 660.0).toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          child: LoginPage(),
        ),
      ),
    );
  }
}
