import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
import 'models/chat_models.dart';

class SocketService {
  static IO.Socket? _socket;

  static Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await ApiService.getToken();
    if (token == null) return;

    _socket = IO.io(
      ApiService.baseUrl,
      IO.OptionBuilder()
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

  static void markSeen({required String conversationId, required String messageId}) {
    _socket?.emit('seen', {'conversationId': conversationId, 'messageId': messageId});
  }

  static void offNewMessage() => _socket?.off('newMessage');
  static void offConversationUpdated() => _socket?.off('conversationUpdated');
  static void offTyping() => _socket?.off('typing');
  static void offStopTyping() => _socket?.off('stopTyping');
}