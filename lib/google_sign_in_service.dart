import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract final class GoogleSignInService {
  static const clientId =
      '704537003987-nhbquge06mbasglpsush74qpj8a42t1n.apps.googleusercontent.com';

  static final GoogleSignIn instance = GoogleSignIn.instance;

  static final Future<void> initialized = instance.initialize(
    clientId: kIsWeb ? clientId : null,
    serverClientId: kIsWeb ? null : clientId,
  );
}
