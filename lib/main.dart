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
import 'l10n/app_locale.dart';
import 'location_service.dart';
import 'login_page.dart';
import 'new_password_page.dart';
import 'notification_service.dart';
import 'promotion_payment_return_page.dart';
import 'register_page.dart';
import 'saved_cards_page.dart';
import 'theme_notifier.dart';
import 'welcome_page.dart';

import 'web/web_shell.dart';
import 'web/web_product_page.dart';

ThemeData _buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF50C878),
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);

  final themedBase = base.copyWith(
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 10,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: scheme.onInverseSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: scheme.inversePrimary,
      disabledActionTextColor: scheme.onInverseSurface.withValues(alpha: .45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      showCloseIcon: true,
      closeIconColor: scheme.onInverseSurface,
    ),
  );

  if (!kIsWeb) return themedBase;

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  );

  return themedBase.copyWith(
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xFFF7F8FA)
        : const Color(0xFF101312),
    visualDensity: VisualDensity.compact,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(38),
        iconSize: 20,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await appLocaleController.load();

  // ============================================================
  // FIREBASE
  // ============================================================

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    await NotificationService.initialize();
  } catch (error, stackTrace) {
    // Notificările sunt auxiliare și nu trebuie să blocheze pornirea aplicației.
    debugPrint('NotificationService initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const MainApp());

  /*
   * Dacă aplicația a fost pornită prin apăsarea unei
   * notificări, NotificationService poate primi mesajul
   * înainte ca Navigator-ul să fie construit.
   *
   * Procesăm navigarea după primul frame.
   */
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.processPendingNavigation();
  });
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
    // INVITE REGISTRATION
    // ============================================================

    final referralCode = uri.queryParameters['ref']?.trim();

    if (referralCode != null && referralCode.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => RegisterPage(referralCode: referralCode),
          ),
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

        return kIsWeb
            ? WebProductPage(productId: listingId)
            : ListingDetailPage(listingId: listingId);
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

    if (path == '/reset-password') {
      final token = uri.queryParameters['token'] ?? '';
      if (token.isNotEmpty) {
        return NewPasswordPage(resetToken: token);
      }
    }

    if (kIsWeb) {
      final hasReferralCode =
          uri.queryParameters['ref']?.trim().isNotEmpty == true;
      final webInitialIndex = path == '/register' || hasReferralCode
          ? 5
          : uri.queryParameters.containsKey('cardSetup')
          ? 15
          : 0;

      return WebShell(initialIndex: webInitialIndex);
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
          return ValueListenableBuilder<String>(
            valueListenable: appLocaleController,
            builder: (context, _, _) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                scaffoldMessengerKey: scaffoldMessengerKey,

                title: 'Nexora Store 🚀',

                debugShowCheckedModeBanner: false,

                themeMode: currentMode,

                // ======================================================
                // LIGHT THEME
                // ======================================================
                theme: _buildAppTheme(Brightness.light),

                // ======================================================
                // DARK THEME
                // ======================================================
                darkTheme: _buildAppTheme(Brightness.dark),

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
                        builder: (_) => kIsWeb
                            ? WebProductPage(productId: listingId)
                            : ListingDetailPage(listingId: listingId),
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

                  if (path == '/reset-password') {
                    final token = uri.queryParameters['token'] ?? '';
                    if (token.isNotEmpty) {
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (_) => NewPasswordPage(resetToken: token),
                      );
                    }
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
          );
        },
      ),
    );
  }
}
