import 'package:flutter/material.dart';

class WebLegalPage extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;
  final Widget? bottom;

  const WebLegalPage({
    super.key,
    required this.title,
    required this.sections,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Nexora',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Nexora Store S.R.L.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: .6,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Ultima actualizare: 3 octombrie 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: .48,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _LegalSection(section: section),
                  ),
                ),

                if (bottom != null) ...[
                  const SizedBox(height: 8),
                  bottom!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final LegalSection section;

  const _LegalSection({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        ...section.paragraphs.map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              paragraph,
              style: TextStyle(
                fontSize: 15,
                height: 1.65,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: .78,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LegalSection {
  final String title;
  final List<String> paragraphs;

  const LegalSection({
    required this.title,
    required this.paragraphs,
  });
}
