import 'package:flutter/material.dart';

import 'widgets/hero_section.dart';
import 'widgets/category_section.dart';
import 'widgets/featured_products.dart';
import 'widgets/new_products.dart';
import 'widgets/recommended_products.dart';
import 'widgets/brands_section.dart';
import 'widgets/why_choose_us.dart';
import 'widgets/web_footer.dart';

class WebHome extends StatelessWidget {
  final VoidCallback? onExplore;
  final ValueChanged<String>? onCategory;

  const WebHome({super.key, this.onExplore, this.onCategory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: HeroSection(onExplore: onExplore)),

          const SliverToBoxAdapter(child: SizedBox(height: 52)),

          SliverToBoxAdapter(child: CategorySection(onCategory: onCategory)),

          const SliverToBoxAdapter(child: SizedBox(height: 56)),

          const SliverToBoxAdapter(child: FeaturedProducts()),

          const SliverToBoxAdapter(child: SizedBox(height: 56)),

          const SliverToBoxAdapter(child: NewProducts()),

          const SliverToBoxAdapter(child: SizedBox(height: 56)),

          const SliverToBoxAdapter(child: RecommendedProducts()),

          const SliverToBoxAdapter(child: SizedBox(height: 56)),

          const SliverToBoxAdapter(child: BrandsSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 56)),

          const SliverToBoxAdapter(child: WhyChooseUs()),

          const SliverToBoxAdapter(child: SizedBox(height: 56)),

          const SliverToBoxAdapter(child: WebFooter()),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
