import 'package:flutter/material.dart';

import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/section_title.dart';
import '../data/demo_categories.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Column(
        children: [
          const SectionTitle(
            title: "Browse Categories",
            subtitle: "Find exactly what you're looking for",
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: demoCategories.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (_, index) {
              final category = demoCategories[index];

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // TODO: Deschide categoria
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            category.color.withValues(alpha: 0.15),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}