import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/orders/models/order_item.dart';
import 'package:greencart_app/src/features/orders/screens/order_tracking_screen.dart';

class OrderTile extends StatelessWidget {
  const OrderTile({required this.order, super.key});

  final OrderItem order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () => context.push(OrderTrackingScreen.pathFor(order.id)),
      child: OrganicCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: order.active
                    ? AppTheme.succulentGreen
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                order.active
                    ? Icons.local_shipping_outlined
                    : Icons.receipt_long_outlined,
                color: order.active ? AppTheme.primary : AppTheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        formatCurrency(order.total),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.status} - ${order.orderNumber}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${order.itemCount} items',
                    style: const TextStyle(
                      color: AppTheme.charcoalInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
