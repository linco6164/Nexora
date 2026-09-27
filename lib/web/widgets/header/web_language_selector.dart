import 'package:flutter/material.dart';

class WebLanguageSelector extends StatefulWidget {
  const WebLanguageSelector({super.key});

  @override
  State<WebLanguageSelector> createState() =>
      _WebLanguageSelectorState();
}

class _WebLanguageSelectorState
    extends State<WebLanguageSelector> {
  String language = "RO";

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: language,
        borderRadius: BorderRadius.circular(12),
        items: const [
          DropdownMenuItem(
            value: "RO",
            child: Text("🇷🇴 RO"),
          ),
          DropdownMenuItem(
            value: "EN",
            child: Text("🇬🇧 EN"),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            language = value;
          });

          // TODO:
          // Save language
        },
      ),
    );
  }
}