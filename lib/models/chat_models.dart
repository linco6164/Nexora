class ChatParticipant {
  final String id;
  final String username;
  final String? avatar;

  ChatParticipant({required this.id, required this.username, this.avatar});

  factory ChatParticipant.fromJson(dynamic json) {
    if (json is String) {
      return ChatParticipant(id: json, username: 'Utilizator', avatar: null);
    }

    final map = json as Map<String, dynamic>;
    return ChatParticipant(
      id: map['_id'] ?? '',
      username: map['username'] ?? 'Necunoscut',
      avatar: map['avatar'],
    );
  }
}

class ConversationListing {
  final String id;
  final String title;
  final double price;
  final List<String> images;

  ConversationListing({
    required this.id,
    required this.title,
    required this.price,
    required this.images,
  });

  factory ConversationListing.fromJson(Map<String, dynamic> json) {
    return ConversationListing(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

class Conversation {
  final String id;
  final List<ChatParticipant> participants;
  final ConversationListing? listing;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, dynamic> unread;

  Conversation({
    required this.id,
    required this.participants,
    this.listing,
    required this.lastMessage,
    this.lastMessageAt,
    required this.unread,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => ChatParticipant.fromJson(p))
          .toList(),
      listing: json['listing'] is Map<String, dynamic>
          ? ConversationListing.fromJson(json['listing'])
          : null,
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'])
          : null,
      unread: Map<String, dynamic>.from(json['unread'] ?? {}),
    );
  }

  ChatParticipant? otherParticipant(String myUserId) {
    try {
      return participants.firstWhere((p) => p.id != myUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }

  int unreadCountFor(String userId) {
    final value = unread[userId];
    if (value is int) return value;
    return 0;
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final ChatParticipant sender;
  final String text;
  final List<String> images;
  final DateTime createdAt;
  final List<String> seenBy;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    required this.images,
    required this.createdAt,
    required this.seenBy,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      conversationId: json['conversation'] is String
          ? json['conversation']
          : json['conversation']?['_id'] ?? '',
      sender: ChatParticipant.fromJson(json['sender'] ?? {}),
      text: json['text'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      seenBy: List<String>.from(json['seenBy'] ?? []),
    );
  }
}
