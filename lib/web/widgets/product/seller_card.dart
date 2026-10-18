import 'package:flutter/material.dart';

import '../../../l10n/app_locale.dart';

class SellerCard extends StatelessWidget {
  final String sellerName;
  final String? avatar;
  final bool verified;
  final int? listingsCount;
  final String? memberSince;
  final VoidCallback? onProfile;

  const SellerCard({
    super.key,
    required this.sellerName,
    this.avatar,
    this.verified = false,
    this.listingsCount = 0,
    this.memberSince = "",
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocaleController.value == 'en'
                  ? 'Product seller'
                  : 'Vânzătorul produsului',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: avatar != null && avatar!.isNotEmpty
                      ? NetworkImage(avatar!)
                      : null,
                  child: avatar == null || avatar!.isEmpty
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              sellerName,
                              style: theme.textTheme.titleMedium?.copyWith(
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
                          appLocaleController.value == 'en'
                              ? '$listingsCount listings'
                              : '$listingsCount anunțuri',
                          style: theme.textTheme.bodyMedium,
                        ),

                      const SizedBox(height: 4),

                      if (memberSince != null)
                        Text(
                          appLocaleController.value == 'en'
                              ? 'Member since $memberSince'
                              : 'Membru din $memberSince',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              appLocaleController.value == 'en'
                  ? 'This is the seller identified in the listing and the contractual party for the product. The fiscal document is issued by the seller when legally required.'
                  : 'Acesta este vânzătorul identificat în anunț și partea contractuală pentru produs. Documentul fiscal este emis de vânzător atunci când există această obligație legală.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onProfile,
                icon: const Icon(Icons.person_outline),
                label: Text(
                  appLocaleController.value == 'en'
                      ? 'View seller profile'
                      : 'Vezi profilul vânzătorului',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
