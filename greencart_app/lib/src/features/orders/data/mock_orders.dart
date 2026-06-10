import 'package:flutter/material.dart';

import '../models/order_item.dart';

const mockOrders = [
  OrderItem(
    id: '#GC-2048',
    status: 'Arriving today',
    window: '5:00 - 7:00 PM',
    total: 42.30,
    itemCount: 7,
    icon: Icons.local_shipping_outlined,
    active: true,
  ),
  OrderItem(
    id: '#GC-1987',
    status: 'Delivered',
    window: 'Yesterday',
    total: 31.15,
    itemCount: 5,
    icon: Icons.check_circle_outline,
    active: false,
  ),
  OrderItem(
    id: '#GC-1921',
    status: 'Delivered',
    window: 'Jun 6',
    total: 55.80,
    itemCount: 9,
    icon: Icons.check_circle_outline,
    active: false,
  ),
];
