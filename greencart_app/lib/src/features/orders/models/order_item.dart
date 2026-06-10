import 'package:flutter/material.dart';

class OrderItem {
  const OrderItem({
    required this.id,
    required this.status,
    required this.window,
    required this.total,
    required this.itemCount,
    required this.icon,
    required this.active,
  });

  final String id;
  final String status;
  final String window;
  final double total;
  final int itemCount;
  final IconData icon;
  final bool active;
}
