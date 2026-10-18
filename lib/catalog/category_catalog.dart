import 'package:flutter/material.dart';

class CategoryNode {
  final String slug;
  final String nameRo;
  final String nameEn;
  final IconData icon;
  final Color color;
  final List<CategoryNode> children;

  const CategoryNode({
    required this.slug,
    required this.nameRo,
    required this.nameEn,
    this.icon = Icons.category_outlined,
    this.color = const Color(0xFF50C878),
    this.children = const [],
  });

  String label(String languageCode) => languageCode == 'en' ? nameEn : nameRo;
}

const listingCategoryCatalog = <CategoryNode>[
  CategoryNode(
    slug: 'fashion',
    nameRo: 'Modă',
    nameEn: 'Fashion',
    icon: Icons.checkroom_outlined,
    color: Color(0xFF6366F1),
    children: [
      CategoryNode(
        slug: 'women',
        nameRo: 'Femei',
        nameEn: 'Women',
        children: [
          CategoryNode(
            slug: 'women-dresses',
            nameRo: 'Rochii',
            nameEn: 'Dresses',
          ),
          CategoryNode(
            slug: 'women-tops',
            nameRo: 'Topuri și bluze',
            nameEn: 'Tops & blouses',
          ),
          CategoryNode(
            slug: 'women-trousers',
            nameRo: 'Pantaloni și jeanși',
            nameEn: 'Trousers & jeans',
          ),
          CategoryNode(
            slug: 'women-jackets',
            nameRo: 'Geci și paltoane',
            nameEn: 'Jackets & coats',
          ),
        ],
      ),
      CategoryNode(
        slug: 'men',
        nameRo: 'Bărbați',
        nameEn: 'Men',
        children: [
          CategoryNode(
            slug: 'men-shirts',
            nameRo: 'Tricouri și cămăși',
            nameEn: 'T-shirts & shirts',
          ),
          CategoryNode(
            slug: 'men-trousers',
            nameRo: 'Pantaloni și jeanși',
            nameEn: 'Trousers & jeans',
          ),
          CategoryNode(
            slug: 'men-jackets',
            nameRo: 'Geci și paltoane',
            nameEn: 'Jackets & coats',
          ),
          CategoryNode(slug: 'men-suits', nameRo: 'Costume', nameEn: 'Suits'),
        ],
      ),
      CategoryNode(
        slug: 'shoes',
        nameRo: 'Încălțăminte',
        nameEn: 'Shoes',
        children: [
          CategoryNode(
            slug: 'sneakers',
            nameRo: 'Sneakers',
            nameEn: 'Sneakers',
          ),
          CategoryNode(
            slug: 'boots',
            nameRo: 'Ghete și cizme',
            nameEn: 'Boots',
          ),
          CategoryNode(
            slug: 'elegant-shoes',
            nameRo: 'Pantofi eleganți',
            nameEn: 'Formal shoes',
          ),
          CategoryNode(slug: 'sandals', nameRo: 'Sandale', nameEn: 'Sandals'),
        ],
      ),
      CategoryNode(
        slug: 'accessories',
        nameRo: 'Accesorii',
        nameEn: 'Accessories',
        children: [
          CategoryNode(
            slug: 'bags',
            nameRo: 'Genți și rucsacuri',
            nameEn: 'Bags & backpacks',
          ),
          CategoryNode(slug: 'watches', nameRo: 'Ceasuri', nameEn: 'Watches'),
          CategoryNode(slug: 'jewelry', nameRo: 'Bijuterii', nameEn: 'Jewelry'),
          CategoryNode(
            slug: 'belts',
            nameRo: 'Curele și portofele',
            nameEn: 'Belts & wallets',
          ),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'electronics',
    nameRo: 'Electronice',
    nameEn: 'Electronics',
    icon: Icons.devices_outlined,
    color: Color(0xFF0EA5E9),
    children: [
      CategoryNode(
        slug: 'phones',
        nameRo: 'Telefoane',
        nameEn: 'Phones',
        children: [
          CategoryNode(
            slug: 'smartphones',
            nameRo: 'Smartphone-uri',
            nameEn: 'Smartphones',
          ),
          CategoryNode(
            slug: 'phone-accessories',
            nameRo: 'Accesorii telefoane',
            nameEn: 'Phone accessories',
          ),
          CategoryNode(
            slug: 'smartwatches',
            nameRo: 'Ceasuri inteligente',
            nameEn: 'Smartwatches',
          ),
        ],
      ),
      CategoryNode(
        slug: 'computers',
        nameRo: 'Calculatoare',
        nameEn: 'Computers',
        children: [
          CategoryNode(slug: 'laptops', nameRo: 'Laptopuri', nameEn: 'Laptops'),
          CategoryNode(
            slug: 'desktop-pc',
            nameRo: 'Desktop PC',
            nameEn: 'Desktop PCs',
          ),
          CategoryNode(
            slug: 'monitors',
            nameRo: 'Monitoare',
            nameEn: 'Monitors',
          ),
          CategoryNode(
            slug: 'pc-components',
            nameRo: 'Componente PC',
            nameEn: 'PC components',
          ),
        ],
      ),
      CategoryNode(
        slug: 'audio-video',
        nameRo: 'Audio și video',
        nameEn: 'Audio & video',
        children: [
          CategoryNode(
            slug: 'televisions',
            nameRo: 'Televizoare',
            nameEn: 'Televisions',
          ),
          CategoryNode(
            slug: 'headphones',
            nameRo: 'Căști',
            nameEn: 'Headphones',
          ),
          CategoryNode(slug: 'speakers', nameRo: 'Boxe', nameEn: 'Speakers'),
          CategoryNode(
            slug: 'cameras',
            nameRo: 'Camere foto-video',
            nameEn: 'Cameras',
          ),
        ],
      ),
      CategoryNode(
        slug: 'gaming',
        nameRo: 'Gaming',
        nameEn: 'Gaming',
        children: [
          CategoryNode(slug: 'consoles', nameRo: 'Console', nameEn: 'Consoles'),
          CategoryNode(
            slug: 'video-games',
            nameRo: 'Jocuri video',
            nameEn: 'Video games',
          ),
          CategoryNode(
            slug: 'gaming-accessories',
            nameRo: 'Accesorii gaming',
            nameEn: 'Gaming accessories',
          ),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'home',
    nameRo: 'Casă și grădină',
    nameEn: 'Home & garden',
    icon: Icons.chair_outlined,
    color: Color(0xFFF59E0B),
    children: [
      CategoryNode(
        slug: 'furniture',
        nameRo: 'Mobilier',
        nameEn: 'Furniture',
        children: [
          CategoryNode(
            slug: 'living-room',
            nameRo: 'Living',
            nameEn: 'Living room',
          ),
          CategoryNode(slug: 'bedroom', nameRo: 'Dormitor', nameEn: 'Bedroom'),
          CategoryNode(
            slug: 'office-furniture',
            nameRo: 'Birou',
            nameEn: 'Office',
          ),
          CategoryNode(
            slug: 'garden-furniture',
            nameRo: 'Mobilier grădină',
            nameEn: 'Garden furniture',
          ),
        ],
      ),
      CategoryNode(
        slug: 'decorations',
        nameRo: 'Decorațiuni',
        nameEn: 'Decor',
        children: [
          CategoryNode(
            slug: 'lighting',
            nameRo: 'Iluminat',
            nameEn: 'Lighting',
          ),
          CategoryNode(slug: 'textiles', nameRo: 'Textile', nameEn: 'Textiles'),
          CategoryNode(
            slug: 'wall-decor',
            nameRo: 'Decorațiuni perete',
            nameEn: 'Wall decor',
          ),
        ],
      ),
      CategoryNode(
        slug: 'appliances',
        nameRo: 'Electrocasnice',
        nameEn: 'Appliances',
        children: [
          CategoryNode(
            slug: 'large-appliances',
            nameRo: 'Electrocasnice mari',
            nameEn: 'Large appliances',
          ),
          CategoryNode(
            slug: 'small-appliances',
            nameRo: 'Electrocasnice mici',
            nameEn: 'Small appliances',
          ),
          CategoryNode(
            slug: 'vacuum-cleaners',
            nameRo: 'Aspiratoare',
            nameEn: 'Vacuum cleaners',
          ),
        ],
      ),
      CategoryNode(
        slug: 'garden',
        nameRo: 'Grădină și bricolaj',
        nameEn: 'Garden & DIY',
        children: [
          CategoryNode(slug: 'tools', nameRo: 'Unelte', nameEn: 'Tools'),
          CategoryNode(slug: 'plants', nameRo: 'Plante', nameEn: 'Plants'),
          CategoryNode(
            slug: 'garden-tools',
            nameRo: 'Echipamente grădină',
            nameEn: 'Garden equipment',
          ),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'beauty',
    nameRo: 'Frumusețe',
    nameEn: 'Beauty',
    icon: Icons.face_retouching_natural_outlined,
    color: Color(0xFFEC4899),
    children: [
      CategoryNode(
        slug: 'makeup',
        nameRo: 'Machiaj',
        nameEn: 'Makeup',
        children: [
          CategoryNode(slug: 'face-makeup', nameRo: 'Ten', nameEn: 'Face'),
          CategoryNode(slug: 'eye-makeup', nameRo: 'Ochi', nameEn: 'Eyes'),
          CategoryNode(slug: 'lip-makeup', nameRo: 'Buze', nameEn: 'Lips'),
        ],
      ),
      CategoryNode(
        slug: 'care',
        nameRo: 'Îngrijire',
        nameEn: 'Personal care',
        children: [
          CategoryNode(
            slug: 'skin-care',
            nameRo: 'Îngrijirea tenului',
            nameEn: 'Skin care',
          ),
          CategoryNode(
            slug: 'hair-care',
            nameRo: 'Îngrijirea părului',
            nameEn: 'Hair care',
          ),
          CategoryNode(
            slug: 'body-care',
            nameRo: 'Îngrijirea corpului',
            nameEn: 'Body care',
          ),
        ],
      ),
      CategoryNode(
        slug: 'perfumes',
        nameRo: 'Parfumuri',
        nameEn: 'Fragrances',
        children: [
          CategoryNode(
            slug: 'women-perfumes',
            nameRo: 'Parfumuri femei',
            nameEn: "Women's fragrances",
          ),
          CategoryNode(
            slug: 'men-perfumes',
            nameRo: 'Parfumuri bărbați',
            nameEn: "Men's fragrances",
          ),
          CategoryNode(
            slug: 'unisex-perfumes',
            nameRo: 'Parfumuri unisex',
            nameEn: 'Unisex fragrances',
          ),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'kids',
    nameRo: 'Copii și bebeluși',
    nameEn: 'Kids & babies',
    icon: Icons.child_friendly_outlined,
    color: Color(0xFFF97316),
    children: [
      CategoryNode(
        slug: 'kids-clothing',
        nameRo: 'Îmbrăcăminte',
        nameEn: 'Clothing',
        children: [
          CategoryNode(slug: 'girls-clothing', nameRo: 'Fete', nameEn: 'Girls'),
          CategoryNode(slug: 'boys-clothing', nameRo: 'Băieți', nameEn: 'Boys'),
          CategoryNode(
            slug: 'baby-clothing',
            nameRo: 'Bebeluși',
            nameEn: 'Babies',
          ),
        ],
      ),
      CategoryNode(
        slug: 'toys',
        nameRo: 'Jucării',
        nameEn: 'Toys',
        children: [
          CategoryNode(
            slug: 'educational-toys',
            nameRo: 'Jucării educative',
            nameEn: 'Educational toys',
          ),
          CategoryNode(
            slug: 'outdoor-toys',
            nameRo: 'Jucării exterior',
            nameEn: 'Outdoor toys',
          ),
          CategoryNode(
            slug: 'plush-toys',
            nameRo: 'Jucării de pluș',
            nameEn: 'Plush toys',
          ),
        ],
      ),
      CategoryNode(
        slug: 'baby-gear',
        nameRo: 'Articole bebeluși',
        nameEn: 'Baby gear',
        children: [
          CategoryNode(
            slug: 'strollers',
            nameRo: 'Cărucioare',
            nameEn: 'Strollers',
          ),
          CategoryNode(
            slug: 'car-seats',
            nameRo: 'Scaune auto',
            nameEn: 'Car seats',
          ),
          CategoryNode(slug: 'feeding', nameRo: 'Hrănire', nameEn: 'Feeding'),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'sports',
    nameRo: 'Sport și timp liber',
    nameEn: 'Sports & leisure',
    icon: Icons.sports_soccer_outlined,
    color: Color(0xFF8B5CF6),
    children: [
      CategoryNode(
        slug: 'fitness',
        nameRo: 'Fitness',
        nameEn: 'Fitness',
        children: [
          CategoryNode(
            slug: 'fitness-equipment',
            nameRo: 'Aparate fitness',
            nameEn: 'Fitness equipment',
          ),
          CategoryNode(slug: 'weights', nameRo: 'Greutăți', nameEn: 'Weights'),
          CategoryNode(slug: 'yoga', nameRo: 'Yoga', nameEn: 'Yoga'),
        ],
      ),
      CategoryNode(
        slug: 'outdoor-sports',
        nameRo: 'Sporturi în aer liber',
        nameEn: 'Outdoor sports',
        children: [
          CategoryNode(
            slug: 'bicycles',
            nameRo: 'Biciclete',
            nameEn: 'Bicycles',
          ),
          CategoryNode(slug: 'camping', nameRo: 'Camping', nameEn: 'Camping'),
          CategoryNode(
            slug: 'winter-sports',
            nameRo: 'Sporturi de iarnă',
            nameEn: 'Winter sports',
          ),
        ],
      ),
      CategoryNode(
        slug: 'team-sports',
        nameRo: 'Sporturi de echipă',
        nameEn: 'Team sports',
        children: [
          CategoryNode(slug: 'football', nameRo: 'Fotbal', nameEn: 'Football'),
          CategoryNode(
            slug: 'basketball',
            nameRo: 'Baschet',
            nameEn: 'Basketball',
          ),
          CategoryNode(slug: 'tennis', nameRo: 'Tenis', nameEn: 'Tennis'),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'auto',
    nameRo: 'Auto și moto',
    nameEn: 'Auto & moto',
    icon: Icons.directions_car_outlined,
    color: Color(0xFFEF4444),
    children: [
      CategoryNode(
        slug: 'vehicles',
        nameRo: 'Vehicule',
        nameEn: 'Vehicles',
        children: [
          CategoryNode(slug: 'cars', nameRo: 'Autoturisme', nameEn: 'Cars'),
          CategoryNode(
            slug: 'motorcycles',
            nameRo: 'Motociclete',
            nameEn: 'Motorcycles',
          ),
          CategoryNode(
            slug: 'commercial-vehicles',
            nameRo: 'Vehicule comerciale',
            nameEn: 'Commercial vehicles',
          ),
        ],
      ),
      CategoryNode(
        slug: 'auto-parts',
        nameRo: 'Piese auto',
        nameEn: 'Auto parts',
        children: [
          CategoryNode(
            slug: 'wheels',
            nameRo: 'Jante și anvelope',
            nameEn: 'Wheels & tires',
          ),
          CategoryNode(
            slug: 'body-parts',
            nameRo: 'Caroserie',
            nameEn: 'Body parts',
          ),
          CategoryNode(
            slug: 'engine-parts',
            nameRo: 'Motor',
            nameEn: 'Engine parts',
          ),
        ],
      ),
      CategoryNode(
        slug: 'auto-accessories',
        nameRo: 'Accesorii auto',
        nameEn: 'Car accessories',
        children: [
          CategoryNode(
            slug: 'car-electronics',
            nameRo: 'Electronică auto',
            nameEn: 'Car electronics',
          ),
          CategoryNode(
            slug: 'interior-accessories',
            nameRo: 'Accesorii interior',
            nameEn: 'Interior accessories',
          ),
          CategoryNode(
            slug: 'car-care',
            nameRo: 'Întreținere auto',
            nameEn: 'Car care',
          ),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'pets',
    nameRo: 'Animale',
    nameEn: 'Pets',
    icon: Icons.pets_outlined,
    color: Color(0xFF10B981),
    children: [
      CategoryNode(
        slug: 'dogs',
        nameRo: 'Câini',
        nameEn: 'Dogs',
        children: [
          CategoryNode(
            slug: 'dog-food',
            nameRo: 'Hrană câini',
            nameEn: 'Dog food',
          ),
          CategoryNode(
            slug: 'dog-accessories',
            nameRo: 'Accesorii câini',
            nameEn: 'Dog accessories',
          ),
          CategoryNode(
            slug: 'dog-hygiene',
            nameRo: 'Igienă câini',
            nameEn: 'Dog hygiene',
          ),
        ],
      ),
      CategoryNode(
        slug: 'cats',
        nameRo: 'Pisici',
        nameEn: 'Cats',
        children: [
          CategoryNode(
            slug: 'cat-food',
            nameRo: 'Hrană pisici',
            nameEn: 'Cat food',
          ),
          CategoryNode(
            slug: 'cat-accessories',
            nameRo: 'Accesorii pisici',
            nameEn: 'Cat accessories',
          ),
          CategoryNode(
            slug: 'cat-litter',
            nameRo: 'Igienă pisici',
            nameEn: 'Cat hygiene',
          ),
        ],
      ),
      CategoryNode(
        slug: 'other-pets',
        nameRo: 'Alte animale',
        nameEn: 'Other pets',
        children: [
          CategoryNode(slug: 'birds', nameRo: 'Păsări', nameEn: 'Birds'),
          CategoryNode(
            slug: 'fish',
            nameRo: 'Pești și acvaristică',
            nameEn: 'Fish & aquatics',
          ),
          CategoryNode(
            slug: 'small-pets',
            nameRo: 'Animale mici',
            nameEn: 'Small pets',
          ),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'books',
    nameRo: 'Media și cărți',
    nameEn: 'Media & books',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF14B8A6),
    children: [
      CategoryNode(
        slug: 'books-category',
        nameRo: 'Cărți',
        nameEn: 'Books',
        children: [
          CategoryNode(
            slug: 'fiction',
            nameRo: 'Beletristică',
            nameEn: 'Fiction',
          ),
          CategoryNode(
            slug: 'non-fiction',
            nameRo: 'Non-ficțiune',
            nameEn: 'Non-fiction',
          ),
          CategoryNode(
            slug: 'school-books',
            nameRo: 'Manuale și cursuri',
            nameEn: 'Textbooks & courses',
          ),
        ],
      ),
      CategoryNode(
        slug: 'music',
        nameRo: 'Muzică',
        nameEn: 'Music',
        children: [
          CategoryNode(slug: 'vinyl', nameRo: 'Viniluri', nameEn: 'Vinyl'),
          CategoryNode(slug: 'cds', nameRo: 'CD-uri', nameEn: 'CDs'),
          CategoryNode(
            slug: 'instruments',
            nameRo: 'Instrumente muzicale',
            nameEn: 'Musical instruments',
          ),
        ],
      ),
      CategoryNode(
        slug: 'movies',
        nameRo: 'Filme',
        nameEn: 'Movies',
        children: [
          CategoryNode(slug: 'dvd', nameRo: 'DVD', nameEn: 'DVD'),
          CategoryNode(slug: 'blu-ray', nameRo: 'Blu-ray', nameEn: 'Blu-ray'),
          CategoryNode(
            slug: 'movie-collectibles',
            nameRo: 'Colecții cinema',
            nameEn: 'Movie collectibles',
          ),
        ],
      ),
    ],
  ),
  CategoryNode(
    slug: 'hobbies',
    nameRo: 'Hobby și colecții',
    nameEn: 'Hobbies & collectibles',
    icon: Icons.interests_outlined,
    color: Color(0xFF7C3AED),
    children: [
      CategoryNode(
        slug: 'collectibles',
        nameRo: 'Colecții',
        nameEn: 'Collectibles',
        children: [
          CategoryNode(
            slug: 'coins',
            nameRo: 'Monede și bancnote',
            nameEn: 'Coins & banknotes',
          ),
          CategoryNode(slug: 'stamps', nameRo: 'Timbre', nameEn: 'Stamps'),
          CategoryNode(
            slug: 'figurines',
            nameRo: 'Figurine',
            nameEn: 'Figurines',
          ),
        ],
      ),
      CategoryNode(
        slug: 'creative',
        nameRo: 'Activități creative',
        nameEn: 'Creative hobbies',
        children: [
          CategoryNode(slug: 'painting', nameRo: 'Pictură', nameEn: 'Painting'),
          CategoryNode(
            slug: 'handmade',
            nameRo: 'Handmade',
            nameEn: 'Handmade',
          ),
          CategoryNode(
            slug: 'photography',
            nameRo: 'Fotografie',
            nameEn: 'Photography',
          ),
        ],
      ),
      CategoryNode(
        slug: 'board-games',
        nameRo: 'Jocuri și puzzle',
        nameEn: 'Games & puzzles',
        children: [
          CategoryNode(
            slug: 'board-games-items',
            nameRo: 'Jocuri de societate',
            nameEn: 'Board games',
          ),
          CategoryNode(slug: 'puzzles', nameRo: 'Puzzle', nameEn: 'Puzzles'),
          CategoryNode(
            slug: 'trading-cards',
            nameRo: 'Cartonașe de colecție',
            nameEn: 'Trading cards',
          ),
        ],
      ),
    ],
  ),
];

CategoryNode categoryBySlug(String slug) {
  return listingCategoryCatalog.firstWhere(
    (category) => category.slug == slug,
    orElse: () => listingCategoryCatalog.first,
  );
}

CategoryNode? findCategoryBySlug(String slug) {
  for (final category in listingCategoryCatalog) {
    if (category.slug == slug) return category;
  }
  return null;
}
