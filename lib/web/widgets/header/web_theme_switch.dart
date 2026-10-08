import 'package:flutter/material.dart';

import '../../../theme_notifier.dart';

class WebThemeSwitch extends StatelessWidget {
  const WebThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final followsSystem = mode == ThemeMode.system;
        final isDark = followsSystem
            ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
            : mode == ThemeMode.dark;

        return Tooltip(
          message: isDark
              ? 'Folosește tema luminoasă'
              : 'Folosește tema întunecată',
          child: Switch(
            value: isDark,
            onChanged: (value) {
              themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        );
      },
    );
  }
}
