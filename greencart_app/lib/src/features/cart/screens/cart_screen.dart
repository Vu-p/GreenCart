import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/widgets/app_nav_bar.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_action_icon.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/cart/data/mock_cart_items.dart';
import 'package:greencart_app/src/features/cart/widgets/cart_item_tile.dart';
import 'package:greencart_app/src/features/cart/widgets/order_summary.dart';
import 'package:greencart_app/src/features/catalog/screens/search_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const routePath = '/cart';

  @override
  Widget build(BuildContext context) {
    final subtotal = mockCartItems.fold<double>(
      0,
      (total, item) => total + item.price * item.quantity,
    );
    const delivery = 2.90;
    final total = subtotal + delivery;

    return Scaffold(
      appBar: AppBar(
        title: MobilePageTitle(
          title: 'Cart',
          subtitle: '${mockCartItems.length} fresh picks ready',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const OrganicPromoBanner(
            eyebrow: 'DELIVERY WINDOW',
            title: 'Today, 5:00 - 7:00 PM',
            subtitle: 'Cold-packed produce, picked this morning.',
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Your Basket'),
          const SizedBox(height: 14),
          for (final item in mockCartItems) ...[
            CartItemTile(item: item),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
          OrderSummary(subtotal: subtotal, delivery: delivery, total: total),
        ],
      ),
      bottomNavigationBar: const AppNavBar(currentIndex: 2),
    );
  }
}
