import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/section_title.dart';
import '../data/demo_categories.dart';

class CategorySection extends StatelessWidget {
  final ValueChanged<String>? onCategory;

  const CategorySection({super.key, this.onCategory});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Column(
        children: [
          SectionTitle(
            title: context.tr('Explorează categoriile'),
            subtitle: appLocaleController.value == 'en'
                ? 'Quickly find what you are looking for'
                : 'Găsește rapid ceea ce cauți',
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: demoCategories.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 205,
              mainAxisExtent: 96,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            itemBuilder: (_, index) {
              final category = demoCategories[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onCategory?.call(category.slug),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: category.color.withValues(
                            alpha: 0.15,
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.localizedName(appLocaleController.value),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
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
