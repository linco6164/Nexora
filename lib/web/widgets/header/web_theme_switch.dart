import 'package:flutter/material.dart';

class WebThemeSwitch extends StatefulWidget {
  const WebThemeSwitch({super.key});

  @override
  State<WebThemeSwitch> createState() =>
      _WebThemeSwitchState();
}

class _WebThemeSwitchState
    extends State<WebThemeSwitch> {
  bool dark = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Theme",
      child: Switch(
        value: dark,
        onChanged: (value) {
          setState(() {
            dark = value;
          });

          // TODO:
          // ThemeProvider
        },
      ),
    );
  }
}