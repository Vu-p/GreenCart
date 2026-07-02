import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_action_icon.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/cart/models/cart_item.dart';
import 'package:greencart_app/src/features/cart/widgets/cart_item_tile.dart';
import 'package:greencart_app/src/features/cart/widgets/order_summary.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';
import 'package:greencart_app/src/features/catalog/screens/search_screen.dart';
import 'package:greencart_app/src/features/catalog/widgets/product_card.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const routePath = '/cart';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Your Cart',
          subtitle: 'Fresh picks ready for checkout',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(cartRepositoryProvider).clear();
              ref.invalidate(cartProvider);
            },
            child: const Text('Clear All'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OrganicActionIcon(
              icon: Icons.add,
              onPressed: () => context.go(SearchScreen.routePath),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(cartProvider),
        child: cartState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 28),
            children: [
              OrganicStateMessage(
                icon: Icons.lock_outline,
                title: 'Login and add groceries to use your cart.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(cartProvider),
              ),
            ],
          ),
          data: (cart) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              AnimatedEntrance(child: _SmartSubstitutionStrip(cart: cart)),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Your Basket'),
              const SizedBox(height: 14),
              if (cart.isEmpty)
                OrganicStateMessage(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your basket is empty.',
                  actionLabel: 'Find groceries',
                  onAction: () => context.go(SearchScreen.routePath),
                )
              else
                for (final item in cart.items) ...[
                  AnimatedEntrance(
                    delay: Duration(
                      milliseconds: 100 + (cart.items.indexOf(item) * 80),
                    ),
                    child: CartItemTile(item: item),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 10),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 420),
                child: OrderSummary(
                  subtotal: cart.subtotal,
                  delivery: cart.deliveryFee,
                  total: cart.total,
                  enabled: !cart.isEmpty,
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Forget something?'),
              const SizedBox(height: 12),
              const _QuickAddRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartSubstitutionStrip extends ConsumerWidget {
  const _SmartSubstitutionStrip({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cart.isEmpty) {
      return OrganicCard(
        padding: const EdgeInsets.all(14),
        color: AppTheme.succulentGreen,
        radius: AppTheme.radiusMd,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ AI Gợi ý tối ưu giỏ hàng',
                    style: TextStyle(
                      color: AppTheme.charcoalInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'AI tự động đề xuất sản phẩm tốt hơn & rẻ hơn cho các món trong giỏ.',
                    style: TextStyle(color: AppTheme.outline, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final firstItem = cart.items.first;
    final subsState = ref.watch(productSubstitutionsProvider(firstItem.productId));

    return subsState.when(
      data: (products) {
        if (products.isEmpty) {
          return OrganicCard(
            padding: const EdgeInsets.all(14),
            color: AppTheme.succulentGreen,
            radius: AppTheme.radiusMd,
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '✅ Giỏ hàng của bạn đã là các lựa chọn tối ưu nhất trong kho!',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.charcoalInk),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF15803D), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✨ AI Đề xuất tối ưu thay thế (Rẻ hơn / Tốt hơn)',
                          style: TextStyle(
                            color: Color(0xFF14532D),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dành cho món "${firstItem.productName}" trong giỏ hàng',
                          style: const TextStyle(color: Color(0xFF166534), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = products[index];
                  final priceDiff = firstItem.unitPrice - item.price;
                  return SizedBox(
                    width: 165,
                    child: Stack(
                      children: [
                        ProductCard(product: item),
                        if (priceDiff > 0)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'RẺ HƠN ${(priceDiff).toStringAsFixed(0)}đ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _QuickAddRow extends ConsumerWidget {
  const _QuickAddRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsState = ref.watch(dealsProductsProvider);
    return dealsState.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.take(6).length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = products[index];
              return InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                onTap: () async {
                  await ref.read(cartRepositoryProvider).addItem(productId: item.id, quantity: 1);
                  ref.invalidate(cartProvider);
                },
                child: SizedBox(
                  width: 86,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          item.imageUrl,
                          width: 64,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 64, height: 58, color: AppTheme.succulentGreen),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.charcoalInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.succulentGreen,
                        child: Icon(Icons.add, color: AppTheme.primary, size: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
