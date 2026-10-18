import 'package:flutter/material.dart';

import '../../../catalog/category_catalog.dart';
import '../../../l10n/app_locale.dart';
import '../../../models/listing.dart';

class ProductSpecifications extends StatelessWidget {
  final Listing listing;

  const ProductSpecifications({super.key, required this.listing});

  Widget _row(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = findCategoryBySlug(listing.category);
    final categoryLabel =
        category?.label(appLocaleController.value) ?? listing.category;
    final subcategory = category?.children
        .where((node) => node.slug == listing.subcategory)
        .firstOrNull;
    final detail = subcategory?.children
        .where((node) => node.slug == listing.categoryDetail)
        .firstOrNull;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
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
              context.tr('Detalii produs'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            _row(context, context.tr('Categorie'), categoryLabel),

            if (subcategory != null) ...[
              const Divider(height: 1),
              _row(
                context,
                context.tr('Subcategorie'),
                subcategory.label(appLocaleController.value),
              ),
            ],

            if (detail != null) ...[
              const Divider(height: 1),
              _row(
                context,
                context.tr('Tip produs'),
                detail.label(appLocaleController.value),
              ),
            ],

            const Divider(height: 1),

            _row(
              context,
              context.tr('Stare'),
              context.tr(listing.conditionLabel),
            ),

            const Divider(height: 1),

            _row(
              context,
              appLocaleController.value == 'en' ? 'Location' : 'Localitate',
              listing.city,
            ),

            if (listing.brand != null && listing.brand!.isNotEmpty) ...[
              const Divider(height: 1),
              _row(context, context.tr('Brand'), listing.brand!),
            ],

            if (listing.size != null && listing.size!.isNotEmpty) ...[
              const Divider(height: 1),
              _row(context, context.tr('Mărime'), listing.size!),
            ],

            if (listing.color != null && listing.color!.isNotEmpty) ...[
              const Divider(height: 1),
              _row(context, context.tr('Culoare'), listing.color!),
            ],

            if (listing.material != null && listing.material!.isNotEmpty) ...[
              const Divider(height: 1),
              _row(context, context.tr('Material'), listing.material!),
            ],

            const Divider(height: 1),

            _row(
              context,
              appLocaleController.value == 'en' ? 'Currency' : 'Monedă',
              listing.currency,
            ),
          ],
        ),
      ),
    );
  }
}
