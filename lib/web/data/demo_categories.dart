import '../../catalog/category_catalog.dart';
import '../models/web_category.dart';

final demoCategories = listingCategoryCatalog
    .map(
      (category) => WebCategory(
        id: category.slug,
        name: category.nameRo,
        nameEn: category.nameEn,
        slug: category.slug,
        icon: category.icon,
        color: category.color,
      ),
    )
    .toList(growable: false);
