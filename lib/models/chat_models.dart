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
  final String? lastMessageStatus;

  Conversation({
    required this.id,
    required this.participants,
    this.listing,
    required this.lastMessage,
    this.lastMessageAt,
    required this.unread,
    required this.lastMessageStatus,
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
      lastMessageStatus: json['lastMessageStatus']?.toString(),
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

class OfferListing {
  final String id;
  final String title;
  final double price;
  final String currency;
  final List<String> images;

  OfferListing({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.images,
  });

  factory OfferListing.fromJson(Map<String, dynamic> json) {
    return OfferListing(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency']?.toString() ?? 'RON',
      images: List<String>.from(json['images'] ?? const []),
    );
  }
}

class Offer {
  final String id;
  final String conversationId;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final String currency;
  final String status;
  final OfferListing? listing;

  Offer({
    required this.id,
    required this.conversationId,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.currency,
    required this.status,
    this.listing,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    final listingJson = json['listing'];

    return Offer(
      id: json['_id']?.toString() ?? '',
      conversationId: json['conversation'] is String
          ? json['conversation']
          : json['conversation']?['_id']?.toString() ?? '',
      listingId: json['listing'] is String
          ? json['listing']
          : json['listing']?['_id']?.toString() ?? '',
      buyerId: json['buyer'] is String
          ? json['buyer']
          : json['buyer']?['_id']?.toString() ?? '',
      sellerId: json['seller'] is String
          ? json['seller']
          : json['seller']?['_id']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency']?.toString() ?? 'RON',
      status: json['status']?.toString() ?? 'pending',
      listing: listingJson is Map<String, dynamic>
          ? OfferListing.fromJson(listingJson)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
}

class ChatMessage {
  final String id;
  final String conversationId;
  final ChatParticipant sender;
  final String text;
  final List<String> images;
  final DateTime createdAt;
  final List<String> deliveredTo;
  final List<String> seenBy;
  final String type;
  final Offer? offer;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    required this.images,
    required this.createdAt,
    required this.deliveredTo,
    required this.seenBy,
    required this.type,
    this.offer,
    required this.isDeleted,
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
      deliveredTo: List<String>.from(json['deliveredTo'] ?? []),
      seenBy: List<String>.from(json['seenBy'] ?? []),
      type: json['type']?.toString() ?? 'text',
      offer: json['offer'] is Map<String, dynamic>
          ? Offer.fromJson(json['offer'])
          : null,
      isDeleted: json['isDeleted'] == true,
    );
  }
}
