import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';
import 'package:greencart_app/src/features/catalog/models/product.dart';

class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});

  static const routePath = '/deals';
  static const couponCodes = ['GREENCART10', 'ORGANIC20', 'FREESHIP50'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Fresh Deals',
          subtitle: 'Seasonal bundles and smart savings',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const AnimatedEntrance(
            child: OrganicPromoBanner(
              eyebrow: 'TODAY ONLY',
              title: 'Save more on organic weekly essentials.',
              subtitle: 'Curated baskets for healthy routines.',
              icon: Icons.sell_outlined,
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Special Deals'),
          const SizedBox(height: 14),
          dealsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (err, stack) => Center(child: Text('Lỗi tải ưu đãi: $err')),
            data: (products) {
              if (products.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Hiện không có sản phẩm ưu đãi đặc biệt nào.'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final product in products) ...[
                    AnimatedEntrance(
                      delay: Duration(
                        milliseconds: 100 + (products.indexOf(product) * 80),
                      ),
                      child: _DealProductCard(product: product),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Coupons'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final code in couponCodes)
                Chip(
                  avatar: const Icon(Icons.confirmation_number_outlined),
                  label: Text(code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DealProductCard extends ConsumerWidget {
  const _DealProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.succulentGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.local_offer_outlined, color: AppTheme.primary, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.coral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'HOT DEAL',
                    style: TextStyle(
                      color: AppTheme.coral,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(product.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formatCurrency(product.price),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrency(product.price * 1.25),
                      style: const TextStyle(
                        color: AppTheme.outline,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () async {
              await ref.read(cartRepositoryProvider).addItem(
                    productId: product.id,
                    quantity: 1,
                  );
              ref.invalidate(cartProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã thêm ${product.name} vào giỏ hàng!')),
                );
              }
            },
            style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
