import 'package:flutter/material.dart';

class WebCategory {
  final String id;
  final String name;
  final String? nameEn;
  final String slug;
  final IconData icon;
  final Color color;
  final String? image;

  const WebCategory({
    required this.id,
    required this.name,
    this.nameEn,
    required this.slug,
    required this.icon,
    required this.color,
    this.image,
  });

  String localizedName(String languageCode) {
    if (languageCode == 'en' && nameEn != null) return nameEn!;
    return name;
  }

  factory WebCategory.fromJson(Map<String, dynamic> json) {
    return WebCategory(
      id: json["_id"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      nameEn: json["nameEn"]?.toString(),
      slug: json["slug"]?.toString() ?? "",
      icon: Icons.category,
      color: Colors.blue,
      image: json["image"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      if (nameEn != null) "nameEn": nameEn,
      "slug": slug,
      "image": image,
    };
  }
}
