import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:startapp/activity_controller.dart';
import 'package:startapp/activity_events.dart';
import 'package:startapp/models/chat_models.dart';

String tokenFor(String userId) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'id': userId})))}.signature';

Conversation conversation(String userId, int unread) => Conversation(
  id: 'conversation',
  participants: [],
  lastMessage: 'Salut',
  unread: {userId: unread},
  lastMessageStatus: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'login refresh does not disconnect newly attached chat listeners',
    () async {
      String? token;
      var disconnects = 0;
      final controller = ActivityController(
        loadToken: () async => token,
        readCache: (_) async => null,
        writeCache: (_, _) async {},
        loadNotifications: () async => (total: 0, favorites: 0),
        loadConversations: () async => [],
        connect: () async {},
        disconnect: () {
          disconnects++;
        },
      );
      addTearDown(controller.dispose);
      controller.start();
      await controller.refresh();
      token = tokenFor('alice');
      activityEvents.add(ActivityEvent.sessionChanged);
      expect(disconnects, 1);
      await controller.refresh();
      expect(disconnects, 1);
    },
  );

  test(
    'offline launch restores the account cache instead of clearing badges',
    () async {
      final controller = ActivityController(
        loadToken: () async => tokenFor('alice'),
        readCache: (id) async {
          expect(id, 'alice');
          return const UnreadActivity(
            notifications: 8,
            favorites: 2,
            messages: 3,
          );
        },
        writeCache: (_, _) async {},
        loadNotifications: () async => throw StateError('offline'),
        loadConversations: () async => throw StateError('offline'),
        connect: () async {},
        disconnect: () {},
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.counts.toJson(), {
        'notifications': 8,
        'messages': 3,
        'favorites': 2,
      });
    },
  );

  test(
    'failed refresh preserves badges, confirmed reads lower the counts',
    () async {
      var offline = false;
      var read = false;
      final controller = ActivityController(
        loadToken: () async => tokenFor('alice'),
        readCache: (_) async => null,
        writeCache: (_, _) async {},
        loadNotifications: () async {
          if (offline) throw StateError('offline');
          return (total: read ? 1 : 6, favorites: read ? 0 : 2);
        },
        loadConversations: () async {
          if (offline) throw StateError('offline');
          return [conversation('alice', read ? 0 : 4)];
        },
        connect: () async {},
        disconnect: () {},
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      offline = true;
      await controller.refresh();
      expect(controller.counts.notifications, 6);
      expect(controller.counts.messages, 4);
      offline = false;
      read = true;
      await controller.refresh();
      expect(controller.counts.toJson(), {
        'notifications': 1,
        'messages': 0,
        'favorites': 0,
      });
    },
  );

  test('push and socket refreshes coalesce and do not double count', () async {
    final response = Completer<({int total, int favorites})>();
    var calls = 0;
    final controller = ActivityController(
      loadToken: () async => tokenFor('alice'),
      readCache: (_) async => null,
      writeCache: (_, _) async {},
      loadNotifications: () {
        calls++;
        return calls == 1
            ? response.future
            : Future.value((total: 3, favorites: 1));
      },
      loadConversations: () async => [conversation('alice', 2)],
      connect: () async {},
      disconnect: () {},
    );
    addTearDown(controller.dispose);
    final first = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    final second = controller.refresh();
    controller.refresh();
    response.complete((total: 3, favorites: 1));
    await Future.wait([first, second]);
    expect(calls, 2);
    expect(controller.counts.toJson(), {
      'notifications': 3,
      'messages': 2,
      'favorites': 1,
    });
  });

  test(
    'a response from the previous account cannot restore its badges',
    () async {
      var token = tokenFor('alice');
      final oldResponse = Completer<({int total, int favorites})>();
      final requested = Completer<void>();
      final cacheUsers = <String>[];
      var calls = 0;
      final controller = ActivityController(
        loadToken: () async => token,
        readCache: (id) async {
          cacheUsers.add(id);
          return null;
        },
        writeCache: (_, _) async {},
        loadNotifications: () {
          calls++;
          if (calls == 1) {
            requested.complete();
            return oldResponse.future;
          }
          return Future.value((total: 0, favorites: 0));
        },
        loadConversations: () async => [],
        connect: () async {},
        disconnect: () {},
      );
      addTearDown(controller.dispose);
      controller.start();
      await requested.future;
      token = tokenFor('bob');
      activityEvents.add(ActivityEvent.sessionChanged);
      final refreshed = controller.refresh();
      oldResponse.complete((total: 99, favorites: 50));
      await refreshed;
      expect(cacheUsers, ['alice', 'bob']);
      expect(controller.counts.notifications, 0);
      expect(controller.counts.favorites, 0);
    },
  );

  test(
    'logout clears badges without losing the account-specific saved state',
    () async {
      String? token = tokenFor('alice');
      final saved = <String, UnreadActivity>{};
      final controller = ActivityController(
        loadToken: () async => token,
        readCache: (id) async => saved[id],
        writeCache: (id, counts) async {
          saved[id] = counts;
        },
        loadNotifications: () async => (total: 5, favorites: 1),
        loadConversations: () async => [conversation('alice', 2)],
        connect: () async {},
        disconnect: () {},
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      await Future<void>.delayed(Duration.zero);
      token = null;
      await controller.refresh();
      expect(controller.counts.notifications, 0);
      expect(controller.counts.messages, 0);
      expect(saved['alice']?.notifications, 5);
    },
  );
}
