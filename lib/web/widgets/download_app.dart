import 'package:flutter/material.dart';

import '../../shared/widgets/responsive_container.dart';

class DownloadApp extends StatelessWidget {
  const DownloadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 80),
      padding: const EdgeInsets.symmetric(vertical: 60),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ResponsiveContainer(
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Download Nexora",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Buy and sell from anywhere using our mobile application.",
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.android),
              label: const Text("Google Play"),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.apple),
              label: const Text("App Store"),
            ),
          ],
        ),
      ),
    );
  }
}