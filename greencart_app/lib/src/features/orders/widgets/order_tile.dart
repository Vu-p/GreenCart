import 'package:flutter/material.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/orders/models/order_item.dart';

class OrderTile extends StatelessWidget {
  const OrderTile({required this.order, super.key});

  final OrderItem order;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
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
              order.icon,
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
                  '${order.status} - ${order.window}',
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
    );
  }
}
