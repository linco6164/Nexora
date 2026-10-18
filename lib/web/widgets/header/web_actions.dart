import 'package:flutter/material.dart';

class WebActions extends StatelessWidget {
  final VoidCallback? onFavorites;
  final VoidCallback? onMessages;
  final VoidCallback? onNotifications;
  final VoidCallback? onSell;
  final bool compact;

  const WebActions({
    super.key,
    this.onFavorites,
    this.onMessages,
    this.onNotifications,
    this.onSell,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onFavorites,
          icon: const Icon(Icons.favorite_border_rounded),
          tooltip: 'Favorite',
        ),

        IconButton(
          onPressed: onMessages,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          tooltip: 'Mesaje',
        ),

        IconButton(
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notificări',
        ),

        SizedBox(width: compact ? 2 : 12),

        if (compact)
          IconButton.filled(
            onPressed: onSell,
            tooltip: 'Vinde',
            icon: const Icon(Icons.add_rounded, size: 20),
          )
        else
          FilledButton.icon(
            onPressed: onSell,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Vinde',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
