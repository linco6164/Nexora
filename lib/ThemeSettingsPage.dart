import 'package:flutter/material.dart';
import 'ThemeNotifier.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temă aplicație')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return ListView(
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Luminos'),
                secondary: const Icon(Icons.light_mode_outlined),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) themeNotifier.value = mode;
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Întunecat'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) themeNotifier.value = mode;
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Automat (sistem)'),
                secondary: const Icon(Icons.brightness_auto_outlined),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (mode) {
                  if (mode != null) themeNotifier.value = mode;
                },
              ),
            ],
          );
        },
      ),
    );
  }
}