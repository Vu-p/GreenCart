import 'package:flutter/material.dart';

class DealBundle {
  const DealBundle({
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.badge,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final String badge;
  final IconData icon;
  final Color color;
}
