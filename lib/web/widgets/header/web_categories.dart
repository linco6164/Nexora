import 'package:flutter/material.dart';

import '../../data/demo_categories.dart';

class WebCategories extends StatelessWidget {
  const WebCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: demoCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = demoCategories[index];

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              // TODO:
              // Open category
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: category.color.withValues(alpha: .12),
              ),
              child: Row(
                children: [
                  Icon(
                    category.icon,
                    color: category.color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}