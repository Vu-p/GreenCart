import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/features/orders/models/order_item.dart';
import 'package:greencart_app/src/features/orders/screens/order_tracking_screen.dart';

class ActiveOrderCard extends StatelessWidget {
  const ActiveOrderCard({required this.orders, super.key});

  final List<OrderItem> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (orders.length > 1) ...[
          Text(
            'LIVE ORDERS (${orders.length})',
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < orders.length; i++) ...[
          _SingleActiveOrderCard(order: orders[i]),
          if (i < orders.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _SingleActiveOrderCard extends StatelessWidget {
  const _SingleActiveOrderCard({required this.order});

  final OrderItem order;

  @override
  Widget build(BuildContext context) {
    final isDelivering = order.status == 'Delivering';
    final isPacking = order.status == 'Packing';

    final heading = isDelivering
        ? 'Driver is on route to you'
        : (isPacking
            ? 'Your produce is being packed'
            : 'Order confirmed & reserved');

    final progressValue = isDelivering ? 1.0 : (isPacking ? 0.66 : 0.33);

    return InkWell(
      onTap: () => context.push(OrderTrackingScreen.pathFor(order.id)),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.deepForest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepForest.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'LIVE ORDER • ${order.orderNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Track',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              heading,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${order.deliverySlot ?? order.deliveryAddress} • ${formatCurrency(order.total)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                color: AppTheme.ripenedOrange,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StepLabel(label: 'Confirmed', active: true),
                _StepLabel(label: 'Packed', active: isPacking || isDelivering),
                _StepLabel(label: 'On route', active: isDelivering),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: active ? Colors.white : Colors.white38,
          fontSize: 12,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}
