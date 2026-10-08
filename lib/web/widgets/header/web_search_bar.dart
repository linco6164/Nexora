import 'package:flutter/material.dart';

class WebSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilters;

  const WebSearchBar({
    super.key,
    this.controller,
    this.onSubmitted,
    this.onFilters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: "Caută produse...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: onFilters,
            icon: const Icon(Icons.tune),
            tooltip: 'Filtre',
          ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
