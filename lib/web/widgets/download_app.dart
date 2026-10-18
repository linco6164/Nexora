import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_locale.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.symmetric(vertical: 36),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ResponsiveContainer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Descarcă aplicația Nexora'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      'Cumpără și vinde de oriunde din aplicația mobilă.',
                    ),
                  ),
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
