import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';
import 'models/chat_models.dart';

import 'package:flutter/material.dart';

class SocketService {
  static io.Socket? _socket;

  static Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await ApiService.getToken();
    if (token == null) return;

    _socket = io.io(
      ApiService.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static void joinConversation(String conversationId) {
    _socket?.emit('joinConversation', conversationId);
  }

  static void leaveConversation(String conversationId) {
    _socket?.emit('leaveConversation', conversationId);
  }

  static void sendMessage({
    required String conversationId,
    required String text,
    List<String> images = const [],
  }) {
    _socket?.emit('sendMessage', {
      'conversationId': conversationId,
      'text': text,
      'images': images,
    });
  }

  static void onNewMessage(void Function(ChatMessage) callback) {
    _socket?.on('newMessage', (data) {
      callback(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
    });
  }

  static void onConversationUpdated(void Function(Conversation) callback) {
    _socket?.on('conversationUpdated', (data) {
      callback(Conversation.fromJson(Map<String, dynamic>.from(data)));
    });
  }

  static void typing(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  static void stopTyping(String conversationId) {
    _socket?.emit('stopTyping', {'conversationId': conversationId});
  }

  static void onTyping(void Function(String userId) callback) {
    _socket?.on('typing', (userId) => callback(userId.toString()));
  }

  static void onStopTyping(void Function(String userId) callback) {
    _socket?.on('stopTyping', (userId) => callback(userId.toString()));
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
