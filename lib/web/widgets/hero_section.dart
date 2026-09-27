import 'package:flutter/material.dart';
import '../../shared/widgets/responsive_container.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff4F46E5),
            Color(0xff2563EB),
          ],
        ),
      ),
      child: ResponsiveContainer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Buy. Sell. Repeat.",
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Discover millions of products from trusted sellers.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: () {},
                    child: const Text("Start shopping"),
                  )
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Icon(
                  Icons.shopping_bag,
                  size: 250,
                  color: Colors.white24,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}