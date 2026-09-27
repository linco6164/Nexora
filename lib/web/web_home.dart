import 'package:flutter/material.dart';

import 'widgets/hero_section.dart';
import 'widgets/category_section.dart';
import 'widgets/featured_products.dart';
import 'widgets/new_products.dart';
import 'widgets/recommended_products.dart';
import 'widgets/brands_section.dart';
import 'widgets/why_choose_us.dart';
import 'widgets/download_app.dart';
import 'widgets/web_footer.dart';

class WebHome extends StatelessWidget {
  const WebHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: HeroSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 64),
          ),

          const SliverToBoxAdapter(
            child: CategorySection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),

          const SliverToBoxAdapter(
            child: FeaturedProducts(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),

          const SliverToBoxAdapter(
            child: NewProducts(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),

          const SliverToBoxAdapter(
            child: RecommendedProducts(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),

          const SliverToBoxAdapter(
            child: BrandsSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),

          const SliverToBoxAdapter(
            child: WhyChooseUs(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),

          const SliverToBoxAdapter(
            child: DownloadApp(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),

          const SliverToBoxAdapter(
            child: WebFooter(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}