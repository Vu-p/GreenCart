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
          title: 'Your Cart',
          subtitle: 'Fresh picks ready for checkout',
        ),
        actions: [
          TextButton(
            onPressed: () => ref.invalidate(cartProvider),
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
              const AnimatedEntrance(child: _SmartSubstitutionStrip()),
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

class _SmartSubstitutionStrip extends StatelessWidget {
  const _SmartSubstitutionStrip();

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.autorenew, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Substitutions',
                  style: TextStyle(
                    color: AppTheme.charcoalInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'We will suggest similar items if something runs out.',
                  style: TextStyle(color: AppTheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.primary),
        ],
      ),
    );
  }
}

class _QuickAddRow extends StatelessWidget {
  const _QuickAddRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Carrots',
        'https://images.unsplash.com/photo-1445282768818-728615cc910a?auto=format&fit=crop&q=80&w=500',
      ),
      (
        'Avocado',
        'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&q=80&w=500',
      ),
      (
        'Spinach',
        'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&q=80&w=500',
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: () => context.go(SearchScreen.routePath),
            child: SizedBox(
              width: 82,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      item.$2,
                      width: 64,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.$1,
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
  }
}
