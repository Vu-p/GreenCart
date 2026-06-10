import 'package:flutter/material.dart';

class CartItem {
  const CartItem({
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.icon,
    required this.color,
  });

  final String name;
  final String category;
  final double price;
  final int quantity;
  final IconData icon;
  final Color color;
}
