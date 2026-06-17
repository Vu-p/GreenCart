import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/quantity_button.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/cart/models/cart_item.dart';

class CartItemTile extends ConsumerStatefulWidget {
  const CartItemTile({required this.item, super.key});

  final CartItem item;

  @override
  ConsumerState<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<CartItemTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

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
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuantityButton(
                    icon: Icons.remove,
                    enabled: !_busy && item.quantity > 1,
                    onPressed: () => _updateQuantity(item.quantity - 1),
                  ),
                  SizedBox(
                    width: 34,
                    child: Center(
                      child: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  QuantityButton(
                    icon: Icons.add,
                    enabled: !_busy && item.quantity < item.stock,
                    onPressed: () => _updateQuantity(item.quantity + 1),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: _busy ? null : () => _removeItem(),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateQuantity(int quantity) async {
    setState(() => _busy = true);
    try {
      await ref.read(cartRepositoryProvider).updateItem(
            productId: widget.item.productId,
            quantity: quantity,
          );
      ref.invalidate(cartProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update cart item.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _removeItem() async {
    setState(() => _busy = true);
    try {
      await ref.read(cartRepositoryProvider).removeItem(widget.item.productId);
      ref.invalidate(cartProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove cart item.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
