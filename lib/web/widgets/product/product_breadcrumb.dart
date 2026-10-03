import 'package:flutter/material.dart';

class ProductBreadcrumb extends StatelessWidget {
  final String category;
  final String title;

  const ProductBreadcrumb({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: .6);

    Widget separator() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Icon(Icons.chevron_right, size: 18, color: secondary),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(onTap: () {}, child: const Text("Home")),
        separator(),
        InkWell(onTap: () {}, child: Text(category)),
        separator(),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
