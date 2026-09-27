import 'package:flutter/material.dart';

import 'cookies_page.dart';

class CookieBanner extends StatefulWidget {
  const CookieBanner({super.key});

  @override
  State<CookieBanner> createState() => _CookieBannerState();
}

class _CookieBannerState extends State<CookieBanner> {
  bool _visible = true;

  void _accept() {
    setState(() {
      _visible = false;
    });
  }

  void _reject() {
    setState(() {
      _visible = false;
    });
  }

  void _openPreferences() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          title: const Text(
            'Preferințe cookie-uri',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Cookie-urile necesare pot fi utilizate pentru funcționarea '
            'platformei. Cookie-urile opționale pot fi activate numai '
            'în condițiile prevăzute de legislația aplicabilă.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Închide'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _accept();
              },
              child: const Text('Acceptă'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Positioned(
      left: 24,
      right: 24,
      bottom: 24,
      child: Material(
        elevation: 18,
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: .20),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.cookie_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Folosim cookie-uri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Nexora utilizează cookie-uri necesare pentru '
                      'funcționarea platformei și, în funcție de '
                      'preferințele tale, tehnologii opționale.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: .62),
                      ),
                    ),

                    const SizedBox(height: 5),

                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CookiesPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Vezi Politica de cookie-uri',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _reject,
                    child: const Text('Respinge'),
                  ),
                  OutlinedButton(
                    onPressed: _openPreferences,
                    child: const Text('Preferințe'),
                  ),
                  FilledButton(
                    onPressed: _accept,
                    child: const Text('Acceptă'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}