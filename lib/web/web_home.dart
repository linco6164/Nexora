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
    final compact = MediaQuery.sizeOf(context).width < 700;
    final sectionGap = compact ? 34.0 : 56.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: HeroSection(onExplore: onExplore)),

          SliverToBoxAdapter(child: SizedBox(height: compact ? 34 : 52)),

          SliverToBoxAdapter(child: CategorySection(onCategory: onCategory)),

          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),

          const SliverToBoxAdapter(child: FeaturedProducts()),

          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),

          const SliverToBoxAdapter(child: NewProducts()),

          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),

          const SliverToBoxAdapter(child: RecommendedProducts()),

          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),

          const SliverToBoxAdapter(child: BrandsSection()),

          SliverToBoxAdapter(child: SizedBox(height: sectionGap)),

          const SliverToBoxAdapter(child: WhyChooseUs()),

          SliverToBoxAdapter(child: SizedBox(height: compact ? 34 : 56)),

          const SliverToBoxAdapter(child: WebFooter()),

          SliverToBoxAdapter(child: SizedBox(height: compact ? 16 : 40)),
        ],
      ),
    );
  }
}
