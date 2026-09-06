class Seller {
  final String id;
  final String username;
  final String? avatar;
  final bool verified;
  final double rating;

  Seller({
    required this.id,
    required this.username,
    this.avatar,
    this.verified = false,
    this.rating = 0,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['_id'] ?? '',
      username: json['username'] ?? 'Necunoscut',
      avatar: json['avatar'],
      verified: json['verified'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
}

class Listing {
  final String id;
  final String title;
  final String description;
  final String category;
  final String condition;
  final double price;
  final String currency;
  final bool negotiable;
  final String city;
  final List<String> images;
  final String? brand;
  final String? color;
  final String? size;
  final bool shipping;
  final int favorites;
  final int views;
  final String status;
  final Seller? seller;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.currency,
    required this.negotiable,
    required this.city,
    required this.images,
    this.brand,
    this.color,
    this.size,
    required this.shipping,
    required this.favorites,
    required this.views,
    required this.status,
    this.seller,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'RON',
      negotiable: json['negotiable'] ?? false,
      city: json['city'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      brand: json['brand'],
      color: json['color'],
      size: json['size'],
      shipping: json['shipping'] ?? true,
      favorites: json['favorites'] ?? 0,
      views: json['views'] ?? 0,
      status: json['status'] ?? 'active',
      seller: json['seller'] is Map<String, dynamic>
          ? Seller.fromJson(json['seller'])
          : null,
    );
  }

  String get conditionLabel {
    switch (condition) {
      case 'new': return 'Nou';
      case 'like_new': return 'Ca nou';
      case 'good': return 'Bună';
      case 'fair': return 'Acceptabilă';
      default: return condition;
    }
  }
}