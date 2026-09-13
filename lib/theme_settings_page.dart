import 'package:flutter/material.dart';
import 'theme_notifier.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temă aplicație'),
      ),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return RadioGroup<ThemeMode>(
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                themeNotifier.value = mode;
              }
            },
            child: ListView(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Luminos'),
                  secondary: const Icon(
                    Icons.light_mode_outlined,
                  ),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Întunecat'),
                  secondary: const Icon(
                    Icons.dark_mode_outlined,
                  ),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Automat (sistem)'),
                  secondary: const Icon(
                    Icons.brightness_auto_outlined,
                  ),
                  value: ThemeMode.system,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}