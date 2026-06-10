import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../products/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/product_card.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(featuredProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GreenCart',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go(SearchScreen.routePath),
            icon: const Icon(Icons.search, color: AppTheme.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(featuredProductsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            GestureDetector(
              onTap: () => context.go(SearchScreen.routePath),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.mistGray,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.outline),
                    SizedBox(width: 12),
                    Text(
                      'Search fresh groceries',
                      style: TextStyle(color: AppTheme.outline, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FRESH DEALS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Organic picks for smarter weekly shopping.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            categories.when(
              data: (items) => _CategoryList(categories: items),
              loading: () => const SizedBox(
                height: 58,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => _InlineError(
                message: 'Could not load categories.',
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
            ),
            const SizedBox(height: 26),
            Text('Fresh Picks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            products.when(
              data: (items) => _ProductGrid(products: items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _InlineError(
                message: 'Could not load products.',
                onRetry: () => ref.invalidate(featuredProductsProvider),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppNavBar(currentIndex: 0),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<GroceryCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text('No categories yet.');
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ActionChip(
            avatar: const Icon(Icons.eco_outlined, color: AppTheme.primary),
            label: Text(category.name),
            onPressed: () => context.go(
              '${SearchScreen.routePath}?categoryId=${category.id}&categoryName=${Uri.encodeComponent(category.name)}',
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: categories.length,
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('No products found.')),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) => ProductCard(product: products[index]),
      itemCount: products.length,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, style: const TextStyle(color: Colors.red)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
