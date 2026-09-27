import 'package:flutter/material.dart';

import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/section_title.dart';

class BrandsSection extends StatelessWidget {
  const BrandsSection({super.key});

  static const brands = [
    "Apple",
    "Samsung",
    "Nike",
    "Adidas",
    "Sony",
    "LG",
    "Lenovo",
    "Asus",
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Column(
        children: [
          const SectionTitle(
            title: "Popular Brands",
          ),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: brands
                .map(
                  (brand) => Chip(
                    label: Text(brand),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}