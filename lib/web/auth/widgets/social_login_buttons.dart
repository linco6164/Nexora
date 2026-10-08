import 'package:flutter/material.dart';

import 'google_web_sign_in_button.dart';

class SocialLoginButtons extends StatelessWidget {
  final Future<void> Function(String idToken) onGoogleCredential;
  final ValueChanged<Object> onGoogleError;
  final VoidCallback? onFacebook;
  final bool loading;

  const SocialLoginButtons({
    super.key,
    required this.onGoogleCredential,
    required this.onGoogleError,
    this.onFacebook,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: [
            GoogleWebSignInButton(
              loading: loading,
              onCredential: onGoogleCredential,
              onError: onGoogleError,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onFacebook,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.facebook),
                label: const Text("Continuă cu Facebook"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
