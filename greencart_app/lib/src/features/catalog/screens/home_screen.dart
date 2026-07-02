import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/animated_pressable.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';
import 'package:greencart_app/src/features/catalog/models/category.dart';
import 'package:greencart_app/src/features/catalog/models/product.dart';
import 'package:greencart_app/src/features/catalog/widgets/product_card.dart';
import 'package:greencart_app/src/features/deals/screens/deals_screen.dart';
import 'package:greencart_app/src/features/meal_planner/data/mock_meal_plans.dart';
import 'package:greencart_app/src/features/meal_planner/screens/meal_planner_screen.dart';
import 'package:greencart_app/src/features/meal_planner/screens/recipe_detail_screen.dart';
import 'package:greencart_app/src/features/notifications/data/notification_repository.dart';
import 'package:greencart_app/src/features/notifications/screens/notifications_screen.dart';

import 'search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(featuredProductsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _HomeHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(featuredProductsProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  children: [
                    const AnimatedEntrance(child: _HeroBanner()),
                    const SizedBox(height: 24),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 80),
                      child: _SectionTitle(
                        title: 'Categories',
                        actionLabel: 'View All',
                        onAction: () => context.go(SearchScreen.routePath),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 140),
                      child: categories.when(
                        data: (items) => _CategoryList(categories: items),
                        loading: () => const SizedBox(
                          height: 92,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stackTrace) => _InlineError(
                          message: 'Could not load categories.',
                          onRetry: () => ref.invalidate(categoriesProvider),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const AnimatedEntrance(
                      delay: Duration(milliseconds: 180),
                      child: _MealPlannerPromoCard(),
                    ),
                    const SizedBox(height: 24),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 200),
                      child: _SectionTitle(
                        title: 'Shop by Meal (Thực đơn Món ăn)',
                        actionLabel: 'Xem tất cả →',
                        onAction: () =>
                            context.push(MealPlannerScreen.routePath),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const AnimatedEntrance(
                      delay: Duration(milliseconds: 260),
                      child: _MealGrid(),
                    ),
                    const SizedBox(height: 26),
                    const AnimatedEntrance(
                      delay: Duration(milliseconds: 320),
                      child: _SectionTitle(title: 'Trending Products'),
                    ),
                    const SizedBox(height: 14),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 380),
                      child: products.when(
                        data: (items) => _ProductGrid(products: items),
                        loading: () => const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stackTrace) => _InlineError(
                          message: 'Could not load products.',
                          onRetry: () =>
                              ref.invalidate(featuredProductsProvider),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.charcoalInk.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'GreenCart',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => context.go(SearchScreen.routePath),
                  icon: const Icon(Icons.search, color: AppTheme.primary),
                ),
                Stack(
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () => context.push(NotificationsScreen.routePath),
                      icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.coral,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SearchPill(
              label: 'Search fresh produce...',
              onTap: () => context.go(SearchScreen.routePath),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () => context.push(DealsScreen.routePath),
      child: AspectRatio(
        aspectRatio: 1.85,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1280',
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.charcoalInk.withValues(alpha: 0.72),
                      AppTheme.charcoalInk.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'LIMITED TIME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Fresh Deals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Up to 30% off on seasonal organics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Dot(active: true),
                    SizedBox(width: 8),
                    _Dot(active: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 1 : 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
      ],
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
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryBubble(category: category);
        },
        separatorBuilder: (context, index) => const SizedBox(width: 18),
        itemCount: categories.length,
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.category});

  final GroceryCategory category;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.go(
        '${SearchScreen.routePath}?categoryId=${category.id}&categoryName=${Uri.encodeComponent(category.name)}',
      ),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.succulentGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(category.name), color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('fruit')) return Icons.apple_outlined;
    if (normalized.contains('vegetable')) return Icons.eco_outlined;
    if (normalized.contains('dairy')) return Icons.egg_alt_outlined;
    if (normalized.contains('meat')) return Icons.set_meal_outlined;
    if (normalized.contains('bakery')) return Icons.bakery_dining_outlined;
    if (normalized.contains('beverage')) return Icons.local_drink_outlined;
    return Icons.spa_outlined;
  }
}

class _MealGrid extends StatelessWidget {
  const _MealGrid();

  @override
  Widget build(BuildContext context) {
    final meals = mealPlans.take(2).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemCount: meals.length,
      itemBuilder: (context, index) => _MealCard(
        title: index == 0 ? 'Sweet & Sour Soup' : 'Braised Pork',
        subtitle: 'Get Ingredients',
        imageUrl: index == 0
            ? 'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&q=80&w=900'
            : 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=900',
        onTap: () => context.push(RecipeDetailScreen.pathFor(meals[index].id)),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.charcoalInk.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: ColoredBox(
                      color: Colors.white24,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.mistGray.withValues(alpha: 0.42),
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
                  fontSize: 14,
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

class _MealPlannerPromoCard extends StatelessWidget {
  const _MealPlannerPromoCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: () => context.push(MealPlannerScreen.routePath),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.deepForest, AppTheme.charcoalInk],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepForest.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.ripenedOrange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'TÍNH NĂNG HOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Thực Đơn Thông Minh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lên thực đơn cả tuần & thêm toàn bộ nguyên liệu chuẩn công thức chỉ với 1 nút bấm!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Khám phá ngay',
                        style: TextStyle(
                          color: AppTheme.ripenedOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, color: AppTheme.ripenedOrange, size: 15),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 38),
            ),
          ],
        ),
      ),
    );
  }
}
