import 'package:flutter/material.dart';

import '../../new_password_page.dart';

class ResetPasswordPage extends StatelessWidget {
  final String resetToken;

  const ResetPasswordPage({super.key, required this.resetToken});

  @override
  Widget build(BuildContext context) => NewPasswordPage(resetToken: resetToken);
}
