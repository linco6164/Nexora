import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.g_mobiledata),
          label: const Text("Continue with Google"),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.facebook),
          label: const Text("Continue with Facebook"),
        ),
      ],
    );
  }
}