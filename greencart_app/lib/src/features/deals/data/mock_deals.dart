import 'package:flutter/material.dart';

import '../models/deal_bundle.dart';

const dealBundles = [
  DealBundle(
    title: 'Organic Breakfast Box',
    description: 'Avocados, berries, yogurt, oats, and farm eggs.',
    price: 24.90,
    originalPrice: 32.40,
    badge: 'SAVE 23%',
    icon: Icons.breakfast_dining_outlined,
    color: Color(0xFFFFF1D6),
  ),
  DealBundle(
    title: 'Lean Meal Prep Kit',
    description: 'Chicken breast, spinach, tomatoes, and brown rice.',
    price: 29.50,
    originalPrice: 38.75,
    badge: 'WEEKLY PICK',
    icon: Icons.restaurant_outlined,
    color: Color(0xFFE1F4EA),
  ),
  DealBundle(
    title: 'Fresh Fruit Basket',
    description: 'Seasonal strawberries, citrus, bananas, and apples.',
    price: 18.25,
    originalPrice: 23.10,
    badge: 'BEST VALUE',
    icon: Icons.local_florist_outlined,
    color: Color(0xFFFFE8EC),
  ),
];

const couponCodes = ['ORGANIC10', 'FREESHIP', 'WEEKLYFRESH'];
