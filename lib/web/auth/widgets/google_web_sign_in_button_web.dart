import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

class GoogleWebSignInButton extends StatefulWidget {
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
  State<GoogleWebSignInButton> createState() => _GoogleWebSignInButtonState();
}

class _GoogleWebSignInButtonState extends State<GoogleWebSignInButton> {
  static const _clientId =
      '704537003987-nhbquge06mbasglpsush74qpj8a42t1n.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn;
  StreamSubscription<GoogleSignInAccount?>? _accountSubscription;
  bool _handlingCredential = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(clientId: _clientId);
    _accountSubscription = _googleSignIn.onCurrentUserChanged.listen((account) {
      if (account != null) {
        unawaited(_handleAccount(account));
      }
    }, onError: (Object error) => widget.onError(error));
  }

  Future<void> _handleAccount(GoogleSignInAccount account) async {
    if (_handlingCredential) return;
    _handlingCredential = true;

    try {
      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const FormatException(
          'Google nu a furnizat tokenul de identitate.',
        );
      }

      await widget.onCredential(idToken);
    } catch (error) {
      widget.onError(error);
    } finally {
      _handlingCredential = false;
    }
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: widget.loading,
      child: AnimatedOpacity(
        opacity: widget.loading ? 0.55 : 1,
        duration: const Duration(milliseconds: 160),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonWidth = constraints.maxWidth
                .clamp(40.0, 400.0)
                .toDouble();

            return SizedBox(
              width: double.infinity,
              height: 44,
              child: Center(
                child: SizedBox(
                  width: buttonWidth,
                  height: 44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: google_web.renderButton(
                      configuration: google_web.GSIButtonConfiguration(
                        type: google_web.GSIButtonType.standard,
                        theme: isDark
                            ? google_web.GSIButtonTheme.filledBlack
                            : google_web.GSIButtonTheme.outline,
                        size: google_web.GSIButtonSize.large,
                        text: google_web.GSIButtonText.continueWith,
                        shape: google_web.GSIButtonShape.pill,
                        logoAlignment: google_web.GSIButtonLogoAlignment.left,
                        minimumWidth: buttonWidth,
                        locale: 'ro',
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
