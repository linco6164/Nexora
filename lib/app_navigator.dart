import 'package:flutter/material.dart';

import 'welcome_page.dart';
import 'socket_service.dart';
import 'api_service.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> handleGlobalSessionExpired() async {
  SocketService.disconnect();

  await ApiService.deleteToken();

  final navigator = navigatorKey.currentState;

  if (navigator == null) return;

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const WelcomePage(),
    ),
    (route) => false,
  );
}