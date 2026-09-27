import 'package:flutter/material.dart';

class WebCategory {
  final String id;
  final String name;
  final String slug;
  final IconData icon;
  final Color color;
  final String? image;

  const WebCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.color,
    this.image,
  });

  factory WebCategory.fromJson(Map<String, dynamic> json) {
    return WebCategory(
      id: json["_id"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
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
      "slug": slug,
      "image": image,
    };
  }
}