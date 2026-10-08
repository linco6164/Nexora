import 'package:flutter/material.dart';

class WebLanguageSelector extends StatelessWidget {
  const WebLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Limba interfeței',
      child: Chip(
        avatar: Icon(Icons.language_rounded, size: 18),
        label: Text('RO'),
      ),
    );
  }
}
