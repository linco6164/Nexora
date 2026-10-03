import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_navigator.dart';
import 'firebase_options.dart';
import 'listing_detail_page.dart';
import 'location_service.dart';
import 'login_page.dart';
import 'new_password_page.dart';
import 'notification_service.dart';
import 'promotion_payment_return_page.dart';
import 'saved_cards_page.dart';
import 'theme_notifier.dart';
import 'welcome_page.dart';

import 'web/web_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE
  // ============================================================

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

  // ============================================================
  // DEEP LINKS
  // ============================================================

  Future<void> _initDeepLinks() async {
    // Pe Web folosim URL-ul normal al paginii.
    // app_links este necesar aici pentru Android/iOS.
    if (kIsWeb) {
      return;
    }

    _appLinks = AppLinks();

    // ============================================================
    // APPLICATION OPENED FROM A DEEP LINK
    // ============================================================

    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        debugPrint('[APP LINKS INITIAL] $initialUri');

        // Așteptăm ca MaterialApp/Navigator să fie construit.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      debugPrint('[APP LINKS INITIAL ERROR] $e');
    }

    // ============================================================
    // APPLICATION ALREADY OPEN
    // ============================================================

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[APP LINKS STREAM] $uri');

        _handleDeepLink(uri);
      },
      onError: (error) {
        debugPrint('[APP LINKS ERROR] $error');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('[APP LINKS] Scheme: ${uri.scheme}');

    debugPrint('[APP LINKS] Host: ${uri.host}');

    debugPrint('[APP LINKS] Path: ${uri.path}');

    debugPrint('[APP LINKS] Query: ${uri.queryParameters}');

    // ============================================================
    // NETOPIA PROMOTION PAYMENT
    // ============================================================

    if (uri.scheme == 'nexora' &&
        uri.host == 'promotion' &&
        uri.path == '/payment-return') {
      final paymentId = uri.queryParameters['paymentId'] ?? '';

      final status = uri.queryParameters['status'] ?? 'pending';

      final orderId = uri.queryParameters['orderId'] ?? '';

      debugPrint('[PROMOTION RETURN] Payment ID: $paymentId');

      debugPrint('[PROMOTION RETURN] Status: $status');

      debugPrint('[PROMOTION RETURN] Order ID: $orderId');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = navigatorKey.currentState;

        if (navigator == null) {
          debugPrint('[PROMOTION RETURN] Navigator unavailable.');
          return;
        }

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PromotionPaymentReturnPage(
              paymentId: paymentId,
              status: status,
            ),
          ),
          (route) => false,
        );
      });

      return;
    }

    if (uri.scheme == 'nexora' &&
        uri.host == 'cards' &&
        uri.path == '/setup-return') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const SavedCardsPage()),
        );
      });

      return;
    }

    // ============================================================
    // RESET PASSWORD
    // ============================================================

    if (uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        debugPrint('[RESET PASSWORD] Token received.');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => NewPasswordPage(resetToken: token),
            ),
          );
        });
      }

      return;
    }
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initDeepLinks();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // INITIAL PAGE
  // ============================================================

  Widget _buildInitialPage() {
    final uri = Uri.base;
    final path = uri.path;

    debugPrint('🌐 Initial Web Path: $path');

    // ============================================================
    // DIRECT PRODUCT URL
    // ============================================================

    if (path.startsWith('/product/')) {
      final listingId = path
          .substring('/product/'.length)
          .split('/')
          .first
          .trim();

      if (listingId.isNotEmpty) {
        debugPrint('🛍️ Opening product directly: $listingId');

        return ListingDetailPage(listingId: listingId);
      }
    }

    // ============================================================
    // PROMOTION PAYMENT RETURN - WEB
    // ============================================================

    if (path == '/promotion/payment-return') {
      final paymentId = uri.queryParameters['paymentId'] ?? '';

      final status = uri.queryParameters['status'] ?? 'pending';

      debugPrint('💳 Promotion payment return - Web');

      debugPrint('💳 Payment ID: $paymentId');

      debugPrint('💳 Status: $status');

      return PromotionPaymentReturnPage(paymentId: paymentId, status: status);
    }

    if (kIsWeb) {
      return WebShell(
        initialIndex: uri.queryParameters.containsKey('cardSetup') ? 15 : 0,
      );
    }

    // ============================================================
    // NORMAL APPLICATION START
    // ============================================================

    return const WelcomePage();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,

            title: 'Nexora Store 🚀',

            debugShowCheckedModeBanner: false,

            themeMode: currentMode,

            // ======================================================
            // LIGHT THEME
            // ======================================================
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF50C878),
              ),
              useMaterial3: true,
            ),

            // ======================================================
            // DARK THEME
            // ======================================================
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF50C878),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),

            // ======================================================
            // INITIAL PAGE
            // ======================================================
            home: _buildInitialPage(),

            // ======================================================
            // ROUTES
            // ======================================================
            onGenerateRoute: (settings) {
              final routeName = settings.name ?? '/';

              final uri = Uri.tryParse(routeName);

              if (uri == null) {
                return null;
              }

              final path = uri.path;

              // ====================================================
              // PRODUCT
              // ====================================================

              if (path.startsWith('/product/')) {
                final listingId = path
                    .substring('/product/'.length)
                    .split('/')
                    .first
                    .trim();

                if (listingId.isNotEmpty) {
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => ListingDetailPage(listingId: listingId),
                  );
                }
              }

              // ====================================================
              // PROMOTION PAYMENT RETURN
              // ====================================================

              if (path == '/promotion/payment-return') {
                final paymentId = uri.queryParameters['paymentId'] ?? '';

                final status = uri.queryParameters['status'] ?? 'pending';

                debugPrint('💳 Promotion payment route');

                debugPrint('💳 Payment ID: $paymentId');

                debugPrint('💳 Status: $status');

                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => PromotionPaymentReturnPage(
                    paymentId: paymentId,
                    status: status,
                  ),
                );
              }

              // ====================================================
              // RESET PASSWORD
              // ====================================================

              if (routeName.startsWith('/?code=')) {
                return MaterialPageRoute(builder: (_) => const LoginPage());
              }

              return null;
            },
          );
        },
      ),
    );
  }
}
