import 'package:flutter/material.dart';

class GoogleWebSignInButton extends StatelessWidget {
  final bool loading;
  final Future<void> Function(String idToken) onCredential;
  final ValueChanged<Object> onError;

  const GoogleWebSignInButton({
    super.key,
    required this.loading,
    required this.onCredential,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
