import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';
import 'activity_events.dart';
import 'models/chat_models.dart';

import 'package:flutter/material.dart';

class SocketService {
  static io.Socket? _socket;
  static Future<void>? _connecting;
  static int _generation = 0;
  static final Set<String> _conversationRooms = <String>{};

  static bool get isConnected => _socket?.connected == true;

  static Future<void> connect() async {
    if (isConnected) return;

    final activeConnection = _connecting;
    if (activeConnection != null) {
      return activeConnection;
    }

    final connection = _connect();
    _connecting = connection;

    try {
      await connection;
    } finally {
      if (identical(_connecting, connection)) {
        _connecting = null;
      }
    }
  }

  static Future<void> _connect() async {
    if (isConnected) return;

    final generation = _generation;
    final token = await ApiService.getToken();
    if (generation != _generation) return;
    if (token == null || token.isEmpty) {
      throw StateError('Nu ești autentificat.');
    }

    final existingSocket = _socket;
    final socket =
        existingSocket ??
        io.io(
          ApiService.baseUrl,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .setAuth({'token': token})
              .enableForceNew()
              .disableAutoConnect()
              .build(),
        );

    _socket = socket;

    if (existingSocket == null) {
      socket.onConnect((_) {
        for (final conversationId in _conversationRooms) {
          socket.emit('joinConversation', conversationId);
        }
        activityEvents.add(ActivityEvent.changed);
      });

      for (final event in [
        'notification:new',
        'notification:unread-count',
        'conversationUpdated',
        'messagesSeen',
      ]) {
        socket.on(event, (_) => activityEvents.add(ActivityEvent.changed));
      }
    }

    final completer = Completer<void>();

    late final void Function(dynamic) handleConnect;
    late final void Function(dynamic) handleConnectError;

    void clearInitialListeners() {
      socket.off('connect', handleConnect);
      socket.off('connect_error', handleConnectError);
    }

    handleConnect = (_) {
      clearInitialListeners();
      if (!completer.isCompleted) completer.complete();
    };

    handleConnectError = (dynamic error) {
      clearInitialListeners();
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Conexiunea pentru mesaje nu a putut fi inițializată.'),
        );
      }
    };

    socket.on('connect', handleConnect);
    socket.on('connect_error', handleConnectError);
    socket.connect();

    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        clearInitialListeners();
        throw TimeoutException('Conexiunea pentru mesaje a expirat.');
      },
    );
  }

  static void disconnect() {
    _generation++;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connecting = null;
    _conversationRooms.clear();
  }

  static void joinConversation(String conversationId) {
    _conversationRooms.add(conversationId);
    if (isConnected) {
      _socket!.emit('joinConversation', conversationId);
    }
  }

  static void leaveConversation(String conversationId) {
    _conversationRooms.remove(conversationId);
    if (isConnected) {
      _socket!.emit('leaveConversation', conversationId);
    }
  }

  static Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    List<String> images = const [],
  }) async {
    await connect();

    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw StateError('Nu există conexiune la mesaje.');
    }

    final normalizedText = text.trim();
    final broadcastCompleter = Completer<ChatMessage>();

    void handleNewMessage(dynamic data) {
      if (broadcastCompleter.isCompleted || data is! Map) return;

      try {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        final hasMatchingImages =
            message.images.length == images.length &&
            message.images.indexed.every(
              (entry) => entry.$2 == images[entry.$1],
            );
        final isSentMessage =
            message.conversationId == conversationId &&
            message.sender.id == senderId &&
            message.text.trim() == normalizedText &&
            hasMatchingImages;

        if (isSentMessage) broadcastCompleter.complete(message);
      } catch (_) {
        // Listenerul principal va trata separat eventualele date nevalide.
      }
    }

    socket.on('newMessage', handleNewMessage);

    try {
      final acknowledgement = socket
          .emitWithAckAsync('sendMessage', {
            'conversationId': conversationId,
            'text': normalizedText,
            'images': images,
          })
          .then((response) {
            if (response is! Map || response['success'] != true) {
              final message = response is Map
                  ? response['message']?.toString()
                  : null;
              throw StateError(message ?? 'Mesajul nu a putut fi trimis.');
            }

            final rawMessage = response['data'];
            if (rawMessage is! Map) {
              throw const FormatException(
                'Răspuns invalid la trimiterea mesajului.',
              );
            }

            return ChatMessage.fromJson(Map<String, dynamic>.from(rawMessage));
          });

      return await Future.any<ChatMessage>([
        acknowledgement,
        broadcastCompleter.future,
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Serverul nu a confirmat trimiterea mesajului.',
        ),
      );
    } finally {
      socket.off('newMessage', handleNewMessage);
    }
  }

  static VoidCallback onNewMessage(void Function(ChatMessage) callback) {
    final socket = _socket;
    if (socket == null) return () {};

    return socket.on('newMessage', (data) {
      callback(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
    });
  }

  static VoidCallback onConversationUpdated(
    void Function(Conversation) callback,
  ) {
    final socket = _socket;
    if (socket == null) return () {};

    return socket.on('conversationUpdated', (data) {
      callback(Conversation.fromJson(Map<String, dynamic>.from(data)));
    });
  }

  static void typing(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  static void stopTyping(String conversationId) {
    _socket?.emit('stopTyping', {'conversationId': conversationId});
  }

  static VoidCallback onTyping(void Function(String userId) callback) {
    final socket = _socket;
    if (socket == null) return () {};

    return socket.on('typing', (userId) => callback(userId.toString()));
  }

  static VoidCallback onStopTyping(void Function(String userId) callback) {
    final socket = _socket;
    if (socket == null) return () {};

    return socket.on('stopTyping', (userId) => callback(userId.toString()));
  }

  static VoidCallback onOfferUpdated(
    void Function(String conversationId) callback,
  ) {
    final socket = _socket;
    if (socket == null) return () {};

    return socket.on('offerUpdated', (data) {
      if (data is Map) {
        final conversationId = data['conversationId']?.toString() ?? '';
        if (conversationId.isNotEmpty) callback(conversationId);
      }
    });
  }

  static VoidCallback onMessageDeleted(
    void Function(String conversationId) callback,
  ) {
    return _onConversationEvent('messageDeleted', callback);
  }

  static VoidCallback onMessagesSeen(
    void Function(String conversationId) callback,
  ) {
    return _onConversationEvent('messagesSeen', callback);
  }

  static VoidCallback _onConversationEvent(
    String event,
    void Function(String conversationId) callback,
  ) {
    final socket = _socket;
    if (socket == null) return () {};

    return socket.on(event, (data) {
      if (data is Map) {
        final conversationId = data['conversationId']?.toString() ?? '';
        if (conversationId.isNotEmpty) callback(conversationId);
      }
    });
  }

  static void markSeen({
    required String conversationId,
    required String messageId,
  }) {
    _socket?.emit('seen', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  static void joinSupportTicket(String ticketId) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('SUPPORT SOCKET: socket not connected');
      return;
    }

    debugPrint('SUPPORT SOCKET: joining $ticketId');

    _socket!.emit('support:join', ticketId);
  }

  static void leaveSupportTicket(String ticketId) {
    if (_socket == null || !_socket!.connected) {
      return;
    }

    debugPrint('SUPPORT SOCKET: leaving $ticketId');

    _socket!.emit('support:leave', ticketId);
  }

  static void sendSupportMessage({
    required String ticketId,
    required String message,
  }) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('SUPPORT SOCKET: socket not connected');
      return;
    }

    debugPrint('SUPPORT SOCKET: sending message to $ticketId');

    _socket!.emit('support:message', {
      'ticketId': ticketId,
      'message': message,
    });
  }

  static void onSupportMessage(
    void Function(Map<String, dynamic> data) callback,
  ) {
    if (_socket == null) {
      return;
    }

    _socket!.off('support:message:new');

    _socket!.on('support:message:new', (data) {
      debugPrint('SUPPORT SOCKET: new message $data');

      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  static void onSupportError(void Function(String message) callback) {
    if (_socket == null) {
      return;
    }

    _socket!.off('support:error');

    _socket!.on('support:error', (data) {
      debugPrint('SUPPORT SOCKET ERROR: $data');

      if (data is Map) {
        callback(
          data['message']?.toString() ?? 'Eroare la conexiunea cu suportul.',
        );
      }
    });
  }

  static void notifySupportTicketCreated(String ticketId) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('SUPPORT SOCKET: not connected');
      return;
    }

    debugPrint('SUPPORT SOCKET: ticket created $ticketId');

    _socket!.emit('support:ticket:created', ticketId);
  }

  static void offNewMessage() => _socket?.off('newMessage');
  static void offConversationUpdated() => _socket?.off('conversationUpdated');
  static void offTyping() => _socket?.off('typing');
  static void offStopTyping() => _socket?.off('stopTyping');

  static void clearSupportListeners() {
    if (_socket == null) {
      return;
    }

    _socket!.off('support:message:new');
    _socket!.off('support:error');
    _socket!.off('support:ticket:updated');
  }
}
