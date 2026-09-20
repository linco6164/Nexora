import 'package:flutter/material.dart';

import 'login_page.dart';

import 'listing_detail_page.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

import 'new_password_page.dart';

import 'theme_notifier.dart';

import 'home_page.dart';

import 'welcome_page.dart';

import 'package:app_links/app_links.dart';

import 'dart:async';

import 'location_service.dart';

import 'app_navigator.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.initialize();

  runApp(const MainApp());
}

final position = LocationService.getCurrentLocation();

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
  Widget _buildInitialPage() {
    final path = Uri.base.path;

    debugPrint('🌐 Initial Web Path: $path');

    // ============================================================
    // DIRECT PRODUCT URL
    // ============================================================

    if (path.startsWith('/product/')) {
      final listingId = path
          .substring('/product/'.length)
          .split('?')
          .first
          .trim();

      if (listingId.isNotEmpty) {
        debugPrint('🛍️ Opening product directly: $listingId');

        return ListingDetailPage(listingId: listingId);
      }
    }

    // ============================================================
    // NORMAL APPLICATION START
    // ============================================================

    return const WelcomePage();
  }

  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Nexora Store 🚀',
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
          home: _buildInitialPage(),
          onGenerateRoute: (settings) {
            final path = settings.name ?? '/';

            // ============================================================
            // PRODUCT
            // ============================================================

            if (path.startsWith('/product/')) {
              final listingId = path
                  .substring('/product/'.length)
                  .split('?')
                  .first
                  .trim();

              if (listingId.isNotEmpty) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => ListingDetailPage(listingId: listingId),
                );
              }
            }

            // ============================================================
            // RESET PASSWORD
            // ============================================================

            if (path.startsWith('/?code=')) {
              return MaterialPageRoute(builder: (_) => const LoginPage());
            }

            return null;
          },
        );
      },
    );
  }
}
