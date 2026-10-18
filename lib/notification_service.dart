import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'app_feedback.dart';
import 'app_navigator.dart';

import 'api_service.dart';
import 'chat_page.dart';
import 'account_banned_page.dart';
import 'invite_friend_page.dart';
import 'order_page.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM BACKGROUND MESSAGE');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ShorebirdUpdater _shorebirdUpdater = ShorebirdUpdater();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  StreamSubscription<String>? _tokenRefreshSubscription;

  String? _registrationId;

  Completer<String?>? _registrationCompleter;

  String? _pendingOrderId;

  static const int _shorebirdNotificationId = 9001;

  static const int _shorebirdRestartNotificationId = 9002;

  static const AndroidNotificationChannel _notificationChannel =
      AndroidNotificationChannel(
        'nexora_notifications',
        'Nexora Notifications',
        description: 'Notificări Nexora Store',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _silentNotificationChannel =
      AndroidNotificationChannel(
        'nexora_notifications_silent',
        'Nexora Notifications Silent',
        description: 'Notificări Nexora Store fără sunet și vibrații',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      );

  static const AndroidNotificationChannel _updateNotificationChannel =
      AndroidNotificationChannel(
        'nexora_updates',
        'Actualizări Nexora',
        description: 'Notificări despre actualizările aplicației Nexora',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  static Future<void> initialize() async {
    final service = NotificationService.instance;

    await service._initialize();
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      debugPrint('[FCM] Web notifications disabled for now.');
      return;
    }

    await _initializeLocalNotifications();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'FCM authorization status: '
      '${settings.authorizationStatus}',
    );

    _tokenRefreshSubscription?.cancel();

    _registrationCompleter ??= Completer<String?>();
    _tokenRefreshSubscription = _messaging.onRegistered.listen((
      registrationId,
    ) async {
      _registrationId = registrationId;
      final completer = _registrationCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete(registrationId);
      }

      debugPrint('FCM REGISTERED: $registrationId');

      await registerTokenWithBackend(registrationId);
    });

    try {
      await _messaging.register();
    } catch (error, stackTrace) {
      debugPrint('FCM: înregistrarea dispozitivului a eșuat: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    _foregroundSubscription?.cancel();

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) async {
      debugPrint('FCM FOREGROUND MESSAGE: ${message.data}');

      final type = message.data['type']?.toString();

      if (type == 'account_banned') {
        final reason = message.data['reason']?.toString() ?? '';

        await _handleAccountBanned(reason);
        return;
      }

      await _showForegroundNotification(message);
    });

    _openedAppSubscription?.cancel();

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      debugPrint('FCM NOTIFICATION OPENED');

      debugPrint('Data: ${message.data}');

      _handleNotificationTap(message);
    });

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('FCM INITIAL MESSAGE');

      _handleNotificationTap(initialMessage);
    }

    /*
     * Shorebird
     *
     * Nu blocăm pornirea aplicației.
     * Verificarea se face în background.
     */
    if (!kIsWeb) {
      _checkForShorebirdUpdate();
    }
  }

  Future<void> _handleAccountBanned(String reason) async {
    debugPrint('ACCOUNT BANNED');
    debugPrint('BAN REASON: $reason');

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AccountBannedPage(reason: reason)),
      (route) => false,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_notificationChannel);

    await androidPlugin?.createNotificationChannel(_silentNotificationChannel);

    await androidPlugin?.createNotificationChannel(_updateNotificationChannel);
  }

  Future<void> _checkForShorebirdUpdate() async {
    if (kIsWeb) {
      debugPrint('[Shorebird] Skipped on Web.');
      return;
    }

    if (!_shorebirdUpdater.isAvailable) {
      debugPrint('[Shorebird] Updater unavailable.');

      return;
    }

    /*
     * Lăsăm aplicația să pornească înainte
     * de a face request-ul de rețea.
     */
    await Future<void>.delayed(const Duration(seconds: 3));

    try {
      debugPrint('[Shorebird] Checking for update...');

      final status = await _shorebirdUpdater.checkForUpdate(
        track: UpdateTrack.stable,
      );

      debugPrint('[Shorebird] Update status: $status');

      switch (status) {
        case UpdateStatus.outdated:
          await _handleShorebirdUpdateAvailable();
          break;

        case UpdateStatus.restartRequired:
          await _showShorebirdRestartNotification();
          break;

        case UpdateStatus.upToDate:
          debugPrint('[Shorebird] App is up to date.');
          break;

        case UpdateStatus.unavailable:
          debugPrint('[Shorebird] Update status unavailable.');
          break;
      }
    } catch (error) {
      debugPrint('[Shorebird] Update check failed: $error');
    }
  }

  Future<void> _handleShorebirdUpdateAvailable() async {
    debugPrint('[Shorebird] Update available.');

    /*
     * Notificăm utilizatorul imediat.
     */
    await _showShorebirdUpdateNotification();

    /*
     * Descărcăm patch-ul.
     *
     * Shorebird îl va aplica la următoarea
     * pornire a aplicației.
     */
    try {
      debugPrint('[Shorebird] Downloading update...');

      await _shorebirdUpdater.update(track: UpdateTrack.stable);

      debugPrint('[Shorebird] Update downloaded successfully.');

      await _showShorebirdRestartNotification();
    } on UpdateException catch (error) {
      debugPrint(
        '[Shorebird] Update download failed: '
        '${error.message}',
      );
    } catch (error) {
      debugPrint('[Shorebird] Update download failed: $error');
    }
  }

  Future<void> _showShorebirdUpdateNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'nexora_updates',
      'Actualizări Nexora',
      channelDescription: 'Notificări despre actualizările aplicației Nexora',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      autoCancel: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: _shorebirdNotificationId,
      title: 'Actualizare Nexora disponibilă',
      body: 'O versiune nouă a aplicației este disponibilă.',
      notificationDetails: notificationDetails,
      payload: 'shorebird_update',
    );
  }

  Future<void> _showShorebirdRestartNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'nexora_updates',
      'Actualizări Nexora',
      channelDescription: 'Notificări despre actualizările aplicației Nexora',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      autoCancel: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: _shorebirdRestartNotificationId,
      title: 'Nexora a fost actualizată',
      body: 'Actualizarea este pregătită. Repornește aplicația pentru a o aplica.',
      notificationDetails: notificationDetails,
      payload: 'shorebird_restart',
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) {
      return;
    }

    final title = notification.title ?? 'Nexora Store';

    final body = notification.body ?? '';

    final conversationId = message.data['conversationId']?.toString();

    final type = message.data['type']?.toString();

    final sound = message.data['sound']?.toString().toLowerCase() != 'false';

    final vibration =
        message.data['vibration']?.toString().toLowerCase() != 'false';

    debugPrint('FCM SOUND: $sound');

    debugPrint('FCM VIBRATION: $vibration');

    final route = message.data['route']?.toString();

    final orderId = message.data['orderId']?.toString();

    final canOpenOrder =
        route == 'order_details' && orderId != null && orderId.isNotEmpty;
    final canOpenReferral = route == 'referrals';
    final canOpenConversation =
        type == 'message' &&
        conversationId != null &&
        conversationId.isNotEmpty;

    final shownInApp = AppFeedback.notification(
      title: title,
      message: body,
      onAction: canOpenOrder || canOpenReferral || canOpenConversation
          ? () => _handleNotificationTap(message)
          : null,
    );

    if (shownInApp) return;

    String? payload;

    if (route == 'order_details' && orderId != null && orderId.isNotEmpty) {
      payload = 'order_details|$orderId';
    } else if (route == 'referrals') {
      payload = 'referrals|open';
    } else if (type == 'message' &&
        conversationId != null &&
        conversationId.isNotEmpty) {
      payload = 'message|$conversationId';
    }

    final channel = sound && vibration
        ? _notificationChannel
        : _silentNotificationChannel;

    await _localNotifications.show(
      id: notification.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: sound && vibration,
          enableVibration: sound && vibration,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> registerTokenWithBackend(String token) async {
    try {
      final jwt = await ApiService.getToken();

      if (jwt == null || jwt.isEmpty) {
        debugPrint('FCM: utilizatorul nu este autentificat.');

        return;
      }

      await ApiService.registerPushToken(
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      );

      debugPrint('FCM: token înregistrat cu succes pe backend.');
    } catch (e) {
      debugPrint('FCM: eroare la înregistrarea token-ului: $e');
    }
  }

  Future<void> registerCurrentTokenWithBackend() async {
    try {
      final jwt = await ApiService.getToken();

      if (jwt == null || jwt.isEmpty) {
        debugPrint('FCM: utilizatorul nu este autentificat.');
        return;
      }

      final token = await getToken();

      if (token == null || token.isEmpty) {
        debugPrint('FCM: token indisponibil.');
        return;
      }

      await registerTokenWithBackend(token);

      debugPrint('FCM: token curent înregistrat după autentificare.');
    } catch (e) {
      debugPrint('FCM: eroare la înregistrarea tokenului după login: $e');
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      return;
    }

    debugPrint('LOCAL NOTIFICATION TAP: $payload');

    /*
     * Shorebird update.
     *
     * Nu trebuie să facem nimic special aici.
     * Patch-ul este deja descărcat și va fi
     * aplicat la următoarea pornire.
     */
    if (payload == 'shorebird_update' || payload == 'shorebird_restart') {
      return;
    }

    final parts = payload.split('|');

    if (parts.length != 2) {
      return;
    }

    final type = parts[0];

    final targetId = parts[1].trim();

    if (targetId.isEmpty) {
      return;
    }

    if (type == 'order_details') {
      _openOrderDetails(targetId);
      return;
    }

    if (type == 'message') {
      _openConversation(targetId);
      return;
    }

    if (type == 'referrals') {
      _openReferrals();
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    final route = data['route']?.toString();

    final orderId = data['orderId']?.toString();

    if (route == 'order_details' && orderId != null && orderId.isNotEmpty) {
      _openOrderDetails(orderId);
      return;
    }

    if (route == 'referrals') {
      _openReferrals();
      return;
    }

    final type = data['type']?.toString();

    final conversationId = data['conversationId']?.toString();

    if (type != 'message') {
      return;
    }

    if (conversationId == null || conversationId.isEmpty) {
      return;
    }

    _openConversation(conversationId);
  }

  void _openReferrals() {
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('FCM: navigator indisponibil pentru invitații.');
      return;
    }

    navigator.push(MaterialPageRoute(builder: (_) => const InviteFriendPage()));
  }

  void _openOrderDetails(String orderId) {
    final cleanOrderId = orderId.trim();

    if (cleanOrderId.isEmpty) {
      return;
    }

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint(
        'FCM: navigator indisponibil, păstrez comanda pentru deschidere.',
      );

      _pendingOrderId = cleanOrderId;

      return;
    }

    _pendingOrderId = null;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(orderId: cleanOrderId),
      ),
    );
  }

  void processPendingNavigation() {
    final orderId = _pendingOrderId;

    if (orderId == null || orderId.isEmpty) {
      return;
    }

    _openOrderDetails(orderId);
  }

  Future<void> _openConversation(String conversationId) async {
    try {
      final currentUser = await ApiService.getCurrentUser();

      final conversations = await ApiService.getConversations();

      final conversation = conversations.firstWhere(
        (item) => item.id == conversationId,
      );

      final myUserId =
          currentUser['_id']?.toString() ?? currentUser['id']?.toString();

      if (myUserId == null || myUserId.isEmpty) {
        return;
      }

      final otherParticipant = conversation.otherParticipant(myUserId);

      if (otherParticipant == null) {
        return;
      }

      final navigator = navigatorKey.currentState;

      if (navigator == null) {
        debugPrint('FCM: navigator indisponibil.');

        return;
      }

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversationId: conversation.id,
            otherUsername: otherParticipant.username,
            myUserId: myUserId,
            listing: conversation.listing,
          ),
        ),
      );
    } catch (e) {
      debugPrint('FCM: failed to open conversation: $e');
    }
  }

  Future<String?> getToken() async {
    if (kIsWeb) return null;

    final currentRegistrationId = _registrationId;
    if (currentRegistrationId != null && currentRegistrationId.isNotEmpty) {
      return currentRegistrationId;
    }

    final completer = _registrationCompleter ??= Completer<String?>();
    await _messaging.register();

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }

  Future<NotificationSettings> getPermissionStatus() async {
    return _messaging.getNotificationSettings();
  }

  Future<void> deleteToken() async {
    await _messaging.unregister();
    _registrationId = null;
    _registrationCompleter = Completer<String?>();
  }

  void dispose() {
    _foregroundSubscription?.cancel();

    _openedAppSubscription?.cancel();

    _tokenRefreshSubscription?.cancel();
  }
}
