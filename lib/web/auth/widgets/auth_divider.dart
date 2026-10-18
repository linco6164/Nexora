import 'package:flutter/material.dart';

import '../../../l10n/app_locale.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(appLocaleController.value == 'en' ? 'OR' : 'SAU'),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
