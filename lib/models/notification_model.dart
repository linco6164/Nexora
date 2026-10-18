import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final String? listingId;
  final String? conversationId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    this.listingId,
    this.conversationId,
    this.metadata = const <String, dynamic>{},
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      listingId: json['listing'] is String
          ? json['listing']
          : json['listing']?['_id'],
      conversationId: json['conversation'] is String
          ? json['conversation']
          : json['conversation']?['_id'],
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const <String, dynamic>{},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String? get route {
    final value = metadata['route']?.toString().trim();

    return value == null || value.isEmpty ? null : value;
  }

  String? get orderId {
    final value = metadata['orderId']?.toString().trim();

    return value == null || value.isEmpty ? null : value;
  }

  IconData get icon {
    if (route == 'referrals') return Icons.group_add_outlined;

    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'favorite':
        return Icons.favorite_border;
      case 'offer':
        return Icons.local_offer_outlined;
      case 'sale':
        return Icons.sell_outlined;
      case 'listing':
        return Icons.storefront_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
