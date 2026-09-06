import 'package:flutter/material.dart';

import 'LoginPage.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'NotificationService.dart';

import 'NewPasswordPage.dart';

import 'ThemeNotifier.dart';

import 'HomePage.dart';

import 'package:app_links/app_links.dart';

import 'dart:async';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await NotificationService.initialize();

  await Supabase.initialize(
    url: 'https://yjuyicsuztawzqffvrdc.supabase.co',
    publishableKey: 'sb_publishable_vysyWyj2WUUhUsvY3IkPGg_y43s9VIs',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == 'reset-password') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => NewPasswordPage(resetToken: token),
              ),
            );
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Login Demo',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF50C878),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF50C878),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomePage(),
          onGenerateRoute: (settings) {
            if (settings.name != null && settings.name!.startsWith('/?code=')) {
              return MaterialPageRoute(builder: (context) => const LoginPage());
            }
            return null;
          },
        );
      },
    );
  }
}
