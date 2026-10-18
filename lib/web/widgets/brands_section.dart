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
            title: "Branduri populare",
            subtitle: "Descoperă rapid produsele brandurilor cunoscute",
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: brands
                .map(
                  (brand) => Chip(
                    avatar: CircleAvatar(
                      radius: 11,
                      child: Text(
                        brand.substring(0, 1),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    label: Text(
                      brand,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
