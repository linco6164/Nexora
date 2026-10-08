import 'package:flutter/material.dart';

class WebActions extends StatelessWidget {
  final VoidCallback? onFavorites;
  final VoidCallback? onMessages;
  final VoidCallback? onNotifications;
  final VoidCallback? onSell;

  const WebActions({
    super.key,
    this.onFavorites,
    this.onMessages,
    this.onNotifications,
    this.onSell,
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

        const SizedBox(width: 12),

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
