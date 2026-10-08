import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/responsive_container.dart';

class DownloadApp extends StatelessWidget {
  final Uri? googlePlayUrl;
  final Uri? appStoreUrl;

  const DownloadApp({super.key, this.googlePlayUrl, this.appStoreUrl});

  Future<void> _openStore(Uri url) async {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

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
                    "Descarcă Nexora",
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text("Cumpără și vinde de oriunde din aplicația mobilă."),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: googlePlayUrl == null
                  ? null
                  : () => _openStore(googlePlayUrl!),
              icon: const Icon(Icons.android),
              label: const Text("Google Play"),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: appStoreUrl == null
                  ? null
                  : () => _openStore(appStoreUrl!),
              icon: const Icon(Icons.apple),
              label: const Text("App Store"),
            ),
          ],
        ),
      ),
    );
  }
}
