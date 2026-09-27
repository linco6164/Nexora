import 'package:flutter/material.dart';

import '../../shared/widgets/responsive_container.dart';
import '../../shared/widgets/section_title.dart';

class WhyChooseUs extends StatelessWidget {
  const WhyChooseUs({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Column(
        children: [
          const SectionTitle(
            title: "Why choose Nexora?",
          ),
          Row(
            children: const [
              Expanded(
                child: _Benefit(
                  Icons.verified_user,
                  "Verified Sellers",
                ),
              ),
              Expanded(
                child: _Benefit(
                  Icons.lock,
                  "Secure Payments",
                ),
              ),
              Expanded(
                child: _Benefit(
                  Icons.local_shipping,
                  "Fast Delivery",
                ),
              ),
              Expanded(
                child: _Benefit(
                  Icons.support_agent,
                  "24/7 Support",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Benefit(
    this.icon,
    this.title,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}