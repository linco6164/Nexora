import 'package:flutter/material.dart';

import '../models/web_category.dart';

const demoCategories = <WebCategory>[
  WebCategory(
    id: "fashion",
    name: "Fashion",
    slug: "fashion",
    icon: Icons.checkroom,
    color: Color(0xff6366F1),
  ),
  WebCategory(
    id: "electronics",
    name: "Electronics",
    slug: "electronics",
    icon: Icons.phone_android,
    color: Color(0xff0EA5E9),
  ),
  WebCategory(
    id: "beauty",
    name: "Beauty",
    slug: "beauty",
    icon: Icons.face,
    color: Color(0xffEC4899),
  ),
  WebCategory(
    id: "home",
    name: "Home",
    slug: "home",
    icon: Icons.chair,
    color: Color(0xffF59E0B),
  ),
  WebCategory(
    id: "auto",
    name: "Auto",
    slug: "auto",
    icon: Icons.directions_car,
    color: Color(0xffEF4444),
  ),
  WebCategory(
    id: "pets",
    name: "Pets",
    slug: "pets",
    icon: Icons.pets,
    color: Color(0xff10B981),
  ),
  WebCategory(
    id: "sports",
    name: "Sports",
    slug: "sports",
    icon: Icons.sports_soccer,
    color: Color(0xff8B5CF6),
  ),
  WebCategory(
    id: "books",
    name: "Books",
    slug: "books",
    icon: Icons.menu_book,
    color: Color(0xff14B8A6),
  ),
];