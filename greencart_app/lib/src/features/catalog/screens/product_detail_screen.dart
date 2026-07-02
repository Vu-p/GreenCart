import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/quantity_button.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';
import 'package:greencart_app/src/features/catalog/widgets/product_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});

  static const routePath = '/products/:id';

  static String pathFor(String productId) => '/products/$productId';

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      body: productState.when(
        data: (product) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 330,
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.charcoalInk,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton.filledTonal(
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      foregroundColor: AppTheme.primary,
                    ),
                    icon: const Icon(Icons.favorite_border),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.04, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.succulentGreen,
                          child: const Icon(
                            Icons.eco_outlined,
                            color: AppTheme.primary,
                            size: 72,
                          ),
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppTheme.surface],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnimatedEntrance(
                    offset: const Offset(0, 28),
                    child: OrganicCard(
                      radius: AppTheme.radiusLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(product.categoryName)),
                              if (product.isOrganic)
                                const Chip(
                                  label: Text('ORGANIC'),
                                  avatar: Icon(Icons.eco_outlined),
                                ),
                              Chip(
                                backgroundColor: product.inStock
                                    ? AppTheme.succulentGreen
                                    : AppTheme.surfaceContainer,
                                label: Text(
                                  product.inStock
                                      ? '${product.stock} in stock'
                                      : 'Out of stock',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.succulentGreen,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  formatCurrency(product.price),
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            product.description,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.outline),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              QuantityButton(
                                icon: Icons.remove,
                                enabled: _quantity > 1,
                                onPressed: () => setState(() => _quantity--),
                              ),
                              Container(
                                width: 56,
                                alignment: Alignment.center,
                                child: Text(
                                  '$_quantity',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              QuantityButton(
                                icon: Icons.add,
                                enabled:
                                    product.inStock &&
                                    _quantity < product.stock,
                                onPressed: () => setState(() => _quantity++),
                              ),
                              const Spacer(),
                              Text(
                                product.inStock
                                    ? 'Ready to add'
                                    : 'Unavailable',
                                style: TextStyle(
                                  color: product.inStock
                                      ? AppTheme.primary
                                      : AppTheme.outline,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: product.inStock
                                ? () async {
                                    try {
                                      await ref
                                          .read(cartRepositoryProvider)
                                          .addItem(
                                            productId: product.id,
                                            quantity: _quantity,
                                          );
                                      ref.invalidate(cartProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Added $_quantity item(s) to cart.',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Could not add item. Please login and try again.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.shopping_cart_outlined),
                            label: Text(
                              product.inStock ? 'Add to Cart' : 'Out of Stock',
                            ),
                          ),
                          _AiRecommendedSection(productId: product.id, currentPrice: product.price),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: OrganicCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Product not found or API unavailable.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(productDetailProvider(widget.productId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiRecommendedSection extends ConsumerWidget {
  const _AiRecommendedSection({required this.productId, required this.currentPrice});

  final String productId;
  final double currentPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsState = ref.watch(productSubstitutionsProvider(productId));
    return subsState.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF15803D), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '✨ AI Gợi ý sản phẩm tối ưu (Rẻ hơn & Tốt hơn)',
                          style: TextStyle(
                            color: Color(0xFF14532D),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sản phẩm cùng danh mục trong kho có giá tốt / ưu đãi tối ưu hơn cho bạn',
                          style: TextStyle(color: Color(0xFF166534), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = products[index];
                  final priceDiff = currentPrice - item.price;
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
                                'RẺ HƠN ${formatCurrency(priceDiff)}',
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
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
