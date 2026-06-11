import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_action_icon.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';
import 'package:greencart_app/src/features/catalog/models/category.dart';
import 'package:greencart_app/src/features/catalog/models/product.dart';
import 'package:greencart_app/src/features/catalog/widgets/product_card.dart';
import 'package:greencart_app/src/features/deals/screens/deals_screen.dart';
import 'package:greencart_app/src/features/meal_planner/screens/meal_planner_screen.dart';

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
        title: MobilePageTitle(
          title: 'GreenCart',
          subtitle: 'Fresh picks for today',
          titleStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OrganicActionIcon(
              icon: Icons.search,
              onPressed: () => context.go(SearchScreen.routePath),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(featuredProductsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _SearchPill(
              label: 'Search fresh groceries',
              onTap: () => context.go(SearchScreen.routePath),
            ),
            const SizedBox(height: 24),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              onTap: () => context.push(DealsScreen.routePath),
              child: const OrganicPromoBanner(
                eyebrow: 'FRESH DEALS',
                title: 'Organic picks for smarter weekly shopping.',
                subtitle: 'Seasonal produce and pantry staples.',
                icon: Icons.local_florist,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () => context.push(MealPlannerScreen.routePath),
              child: const OrganicCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Plan meals from your fresh basket',
                        style: TextStyle(
                          color: AppTheme.charcoalInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppTheme.outline),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeader(title: 'Categories'),
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
            const SectionHeader(title: 'Fresh Picks'),
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
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppTheme.softShadow,
            ),
            child: ActionChip(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.mistGray),
              avatar: const Icon(Icons.eco_outlined, color: AppTheme.primary),
              label: Text(category.name),
              labelStyle: const TextStyle(
                color: AppTheme.charcoalInk,
                fontWeight: FontWeight.w700,
              ),
              onPressed: () => context.go(
                '${SearchScreen.routePath}?categoryId=${category.id}&categoryName=${Uri.encodeComponent(category.name)}',
              ),
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
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
    return OrganicStateMessage(
      icon: Icons.wifi_off_outlined,
      title: message,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.outline,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.tune, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
