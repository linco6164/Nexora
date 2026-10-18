import 'package:flutter/material.dart';

class WebLogo extends StatelessWidget {
  final VoidCallback? onTap;
  final bool compact;

  const WebLogo({super.key, this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          onTap ??
          () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Row(
        children: [
          Icon(
            Icons.shopping_bag_rounded,
            size: 34,
            color: Theme.of(context).colorScheme.primary,
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            Text(
              "NEXORA",
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ],
        ],
      ),
    );
  }
}
