import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity_events.dart';
import 'api_service.dart';
import 'models/chat_models.dart';
import 'socket_service.dart';

class UnreadActivity {
  final int notifications;
  final int messages;
  final int favorites;

  const UnreadActivity({
    this.notifications = 0,
    this.messages = 0,
    this.favorites = 0,
  });

  factory UnreadActivity.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = int.tryParse('${json[key]}') ?? 0;
      return value < 0 ? 0 : value;
    }

    return UnreadActivity(
      notifications: count('notifications'),
      messages: count('messages'),
      favorites: count('favorites'),
    );
  }

  Map<String, int> toJson() => {
    'notifications': notifications,
    'messages': messages,
    'favorites': favorites,
  };
}

class ActivityController extends ChangeNotifier with WidgetsBindingObserver {
  ActivityController({
    Future<String?> Function()? loadToken,
    Future<({int total, int favorites})> Function()? loadNotifications,
    Future<List<Conversation>> Function()? loadConversations,
    Future<UnreadActivity?> Function(String)? readCache,
    Future<void> Function(String, UnreadActivity)? writeCache,
    Future<void> Function()? connect,
    VoidCallback? disconnect,
  }) : _loadToken = loadToken ?? ApiService.getToken,
       _loadNotifications = loadNotifications ?? ApiService.getUnreadActivity,
       _loadConversations = loadConversations ?? ApiService.getConversations,
       _readCache = readCache ?? _readPreferences,
       _writeCache = writeCache ?? _writePreferences,
       _connect = connect ?? SocketService.connect,
       _disconnect = disconnect ?? SocketService.disconnect;

  final Future<String?> Function() _loadToken;
  final Future<({int total, int favorites})> Function() _loadNotifications;
  final Future<List<Conversation>> Function() _loadConversations;
  final Future<UnreadActivity?> Function(String) _readCache;
  final Future<void> Function(String, UnreadActivity) _writeCache;
  final Future<void> Function() _connect;
  final VoidCallback _disconnect;
  UnreadActivity _counts = const UnreadActivity();
  UnreadActivity get counts => _counts;

  String? _token;
  String? _userId;
  int _epoch = 0;
  bool _started = false;
  bool _refreshAgain = false;
  bool _foreground = true;
  Future<void>? _refreshing;
  Future<void> _saving = Future<void>.value();
  Timer? _poll;
  Timer? _debounce;
  StreamSubscription<ActivityEvent>? _events;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _events = activityEvents.stream.listen((event) {
      if (event == ActivityEvent.sessionChanged) {
        _epoch++;
        _token = null;
        _userId = null;
        _disconnect();
        _setCounts(const UnreadActivity());
      }
      _scheduleRefresh();
    });
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground) unawaited(refresh());
    });
    unawaited(refresh());
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (_foreground) unawaited(refresh());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(refresh());
  }

  Future<void> refresh() {
    final active = _refreshing;
    if (active != null) {
      _refreshAgain = true;
      return active;
    }
    final task = _refreshLoop();
    _refreshing = task;
    return task;
  }

  Future<void> _refreshLoop() async {
    try {
      do {
        _refreshAgain = false;
        await _refreshOnce();
      } while (_refreshAgain);
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _refreshOnce() async {
    final epoch = _epoch;
    try {
      final token = await _loadToken();
      if (epoch != _epoch) return;
      if (token != _token) {
        final hadSession = _token != null;
        _token = token;
        _userId = _cacheUserId(token);
        // A sessionChanged event already disconnected the previous account.
        // Do not disconnect pages that just connected after a successful login.
        if (hadSession) _disconnect();
        _setCounts(const UnreadActivity());
        final userId = _userId;
        if (userId != null) {
          try {
            final cached = await _readCache(userId);
            if (epoch != _epoch) return;
            if (cached != null) _setCounts(cached);
          } catch (error) {
            debugPrint('Activity cache: $error');
          }
        }
      }
      if (token == null || token.isEmpty || epoch != _epoch) return;
      unawaited(
        _connect().catchError((Object error) {
          debugPrint('Activity socket: $error');
        }),
      );
      // One failed endpoint must not erase the other counters.
      var notifications = _counts.notifications;
      var favorites = _counts.favorites;
      var messages = _counts.messages;
      await Future.wait([
        () async {
          try {
            final result = await _loadNotifications().timeout(
              const Duration(seconds: 12),
            );
            notifications = result.total;
            favorites = result.favorites;
          } catch (error) {
            debugPrint('Unread notifications: $error');
          }
        }(),
        () async {
          try {
            final conversations = await _loadConversations().timeout(
              const Duration(seconds: 12),
            );
            if (_userId != null) {
              messages = conversations.fold<int>(
                0,
                (total, item) => total + item.unreadCountFor(_userId!),
              );
            }
          } catch (error) {
            debugPrint('Unread messages: $error');
          }
        }(),
      ]);
      if (epoch != _epoch) return;
      final updated = UnreadActivity(
        notifications: notifications,
        favorites: favorites,
        messages: messages,
      );
      _setCounts(updated);
      final userId = _userId;
      if (userId != null) {
        // Serialize cache writes so an older response cannot overwrite a read.
        _saving = _saving
            .then((_) => _writeCache(userId, updated))
            .catchError((Object error) => debugPrint('Activity cache: $error'));
      }
    } catch (error) {
      debugPrint('Activity refresh: $error');
    }
  }

  // Only a cache namespace, never used to authorize a request.
  static String? _cacheUserId(String? token) {
    if (token == null) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))),
      ) as Map<String, dynamic>;
      return (payload['id'] ?? payload['sub'] ?? payload['userId'])?.toString();
    } catch (_) {
      return null;
    }
  }

  void _setCounts(UnreadActivity value) {
    if (_counts.notifications == value.notifications &&
        _counts.messages == value.messages &&
        _counts.favorites == value.favorites) {
      return;
    }
    _counts = value;
    notifyListeners();
  }

  static Future<UnreadActivity?> _readPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('unread_activity_v1_$userId');
    return cached == null
        ? null
        : UnreadActivity.fromJson(
            Map<String, dynamic>.from(jsonDecode(cached) as Map),
          );
  }

  static Future<void> _writePreferences(
    String userId,
    UnreadActivity counts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'unread_activity_v1_$userId',
      jsonEncode(counts.toJson()),
    );
  }

  @override
  void dispose() {
    _epoch++;
    _refreshAgain = false;
    _poll?.cancel();
    _debounce?.cancel();
    _events?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final activityController = ActivityController();
