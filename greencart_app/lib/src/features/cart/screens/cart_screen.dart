import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_action_icon.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/cart/widgets/cart_item_tile.dart';
import 'package:greencart_app/src/features/cart/widgets/order_summary.dart';
import 'package:greencart_app/src/features/catalog/screens/search_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const routePath = '/cart';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Cart',
          subtitle: 'Fresh picks ready',
        ),
        actions: [
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
              const AnimatedEntrance(
                child: OrganicPromoBanner(
                  eyebrow: 'DELIVERY WINDOW',
                  title: 'Today, 5:00 - 7:00 PM',
                  subtitle: 'Cold-packed produce, picked this morning.',
                  icon: Icons.local_shipping_outlined,
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
