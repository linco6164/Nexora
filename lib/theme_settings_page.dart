import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme_notifier.dart';
import 'web/widgets/web_page_frame.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final body = ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return RadioGroup<ThemeMode>(
          groupValue: currentMode,
          onChanged: (mode) {
            if (mode != null) themeNotifier.value = mode;
          },
          child: ListView(
            padding: EdgeInsets.all(kIsWeb ? 10 : 0),
            children: const [
              RadioListTile<ThemeMode>(
                title: Text('Luminos'),
                subtitle: Text('Fundal deschis și contrast clar'),
                secondary: Icon(Icons.light_mode_outlined),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: Text('Întunecat'),
                subtitle: Text('Confort vizual în lumină redusă'),
                secondary: Icon(Icons.dark_mode_outlined),
                value: ThemeMode.dark,
              ),
              RadioListTile<ThemeMode>(
                title: Text('Automat'),
                subtitle: Text('Urmează tema sistemului'),
                secondary: Icon(Icons.brightness_auto_outlined),
                value: ThemeMode.system,
              ),
            ],
          ),
        );
      },
    );

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text('Temă aplicație')),
      body: kIsWeb
          ? WebPageFrame(
              title: 'Tema site-ului',
              subtitle: 'Personalizează aspectul interfeței Nexora',
              maxWidth: 760,
              child: body,
            )
          : body,
    );
  }
}
