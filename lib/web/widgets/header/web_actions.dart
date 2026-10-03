import 'package:flutter/material.dart';

class WebActions extends StatelessWidget {
  const WebActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite_border_rounded),
          tooltip: 'Favorite',
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          tooltip: 'Mesaje',
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notificări',
        ),

        const SizedBox(width: 12),

        FilledButton.icon(
          onPressed: () {
            debugPrint('=== VINDE APASAT ===');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('BUTONUL VINDE FUNCTIONEAZA')),
            );
          },
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
