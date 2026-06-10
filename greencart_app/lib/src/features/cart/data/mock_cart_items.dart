import 'package:flutter/material.dart';

import '../models/cart_item.dart';

const mockCartItems = [
  CartItem(
    name: 'Organic Avocado Pack',
    category: 'Fresh Produce',
    price: 8.40,
    quantity: 2,
    icon: Icons.spa_outlined,
    color: Color(0xFFDDF4E6),
  ),
  CartItem(
    name: 'Oat Milk Barista',
    category: 'Dairy Alternatives',
    price: 4.75,
    quantity: 1,
    icon: Icons.local_drink_outlined,
    color: Color(0xFFFFF1D6),
  ),
  CartItem(
    name: 'Farm Eggs',
    category: 'Pantry',
    price: 6.25,
    quantity: 1,
    icon: Icons.egg_alt_outlined,
    color: Color(0xFFF0F4F2),
  ),
];
