import 'package:flutter/material.dart';

class WebLogo extends StatelessWidget {
  const WebLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Navigate Home
      },
      child: Row(
        children: [
          Icon(
            Icons.shopping_bag_rounded,
            size: 34,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            "NEXORA",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ),
        ],
      ),
    );
  }
}