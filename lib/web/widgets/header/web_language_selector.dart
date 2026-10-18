import 'package:flutter/material.dart';

import '../../../l10n/app_locale.dart';

class WebLanguageSelector extends StatelessWidget {
  const WebLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLocaleController,
      builder: (context, languageCode, _) {
        return PopupMenuButton<String>(
          tooltip: context.tr('Limba interfeței'),
          initialValue: languageCode,
          onSelected: appLocaleController.changeLanguage,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'ro',
              child: _LanguageOption(
                code: 'RO',
                label: context.tr('Română'),
                selected: languageCode == 'ro',
              ),
            ),
            PopupMenuItem(
              value: 'en',
              child: _LanguageOption(
                code: 'EN',
                label: context.tr('Engleză'),
                selected: languageCode == 'en',
              ),
            ),
          ],
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, size: 18),
                const SizedBox(width: 7),
                Text(
                  languageCode.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;

  const _LanguageOption({
    required this.code,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            code,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(child: Text(label)),
        if (selected)
          Icon(
            Icons.check_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}
