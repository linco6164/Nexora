import 'package:flutter/material.dart';

class SellerCard extends StatelessWidget {
  final String sellerName;
  final String? avatar;
  final bool verified;
  final int? listingsCount;
  final String? memberSince;

  const SellerCard({
    super.key,
    required this.sellerName,
    this.avatar,
    this.verified = false,
    this.listingsCount = 0,
    this.memberSince = "",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withOpacity(.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seller",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: avatar != null && avatar!.isNotEmpty
                      ? NetworkImage(avatar!)
                      : null,
                  child: avatar == null || avatar!.isEmpty
                      ? const Icon(Icons.person, size: 34)
                      : null,
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              sellerName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          if (verified) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      if (listingsCount != null)
                        Text(
                          "$listingsCount listings",
                          style: theme.textTheme.bodyMedium,
                        ),

                      const SizedBox(height: 4),

                      if (memberSince != null)
                        Text(
                          "Member since $memberSince",
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text("Message"),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_outline),
                    label: const Text("Profile"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
