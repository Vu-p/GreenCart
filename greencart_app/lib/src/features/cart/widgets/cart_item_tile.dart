import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/cart/models/cart_item.dart';

class CartItemTile extends ConsumerWidget {
  const CartItemTile({required this.item, super.key});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrganicCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              item.imageUrl,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.succulentGreen,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.mistGray),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: AppTheme.primary,
                  size: 32,
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
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.stock} in stock',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(item.unitPrice),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.succulentGreen,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    if (item.quantity > 1) {
                      await ref.read(cartRepositoryProvider).updateItem(
                            productId: item.productId,
                            quantity: item.quantity - 1,
                          );
                    } else {
                      await ref.read(cartRepositoryProvider).removeItem(item.productId);
                    }
                    ref.invalidate(cartProvider);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.remove, size: 16, color: AppTheme.primary),
                  ),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await ref.read(cartRepositoryProvider).updateItem(
                          productId: item.productId,
                          quantity: item.quantity + 1,
                        );
                    ref.invalidate(cartProvider);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.add, size: 16, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () async {
              await ref.read(cartRepositoryProvider).removeItem(item.productId);
              ref.invalidate(cartProvider);
            },
            icon: const Icon(Icons.delete_outline, color: AppTheme.outline),
          ),
        ],
      ),
    );
  }
}
