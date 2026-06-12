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
    final thumbnail = order.items.isNotEmpty
        ? order.items.first.imageUrl
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () => context.push(OrderTrackingScreen.pathFor(order.id)),
      child: OrganicCard(
        padding: const EdgeInsets.all(12),
        radius: AppTheme.radiusLg,
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: thumbnail == null
                      ? Container(
                          width: 72,
                          height: 72,
                          color: AppTheme.succulentGreen,
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppTheme.primary,
                          ),
                        )
                      : Image.network(
                          thumbnail,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 72,
                                height: 72,
                                color: AppTheme.succulentGreen,
                                child: const Icon(
                                  Icons.eco_outlined,
                                  color: AppTheme.primary,
                                ),
                              ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${order.orderNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${order.itemCount} items - ${order.status}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatCurrency(order.total),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: order.active
                        ? AppTheme.succulentGreen
                        : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.active ? 'ACTIVE' : 'DONE',
                    style: TextStyle(
                      color: order.active ? AppTheme.primary : AppTheme.outline,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (order.active) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push(OrderTrackingScreen.pathFor(order.id)),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text('Track Order'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
