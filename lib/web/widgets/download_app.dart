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
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).width < 600 ? 26 : 36,
      ),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ResponsiveContainer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Descarcă aplicația Nexora'),
                  style: TextStyle(
                    fontSize: compact ? 23 : 28,
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
            );
            final buttons = Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: googlePlayUrl == null
                      ? null
                      : () => _openStore(googlePlayUrl!),
                  icon: const Icon(Icons.android),
                  label: const Text("Google Play"),
                ),
                OutlinedButton.icon(
                  onPressed: appStoreUrl == null
                      ? null
                      : () => _openStore(appStoreUrl!),
                  icon: const Icon(Icons.apple),
                  label: const Text("App Store"),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, const SizedBox(height: 20), buttons],
              );
            }

            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 24),
                buttons,
              ],
            );
          },
        ),
      ),
    );
  }
}
