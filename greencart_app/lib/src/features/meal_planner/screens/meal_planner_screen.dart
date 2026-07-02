import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/core/widgets/floating_cart_button.dart';
import 'package:greencart_app/src/features/meal_planner/data/meal_plan_repository.dart';
import 'package:greencart_app/src/features/meal_planner/models/meal_plan.dart';
import 'package:greencart_app/src/features/meal_planner/screens/recipe_detail_screen.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  static const routePath = '/meal-planner';

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All Recipes', 'Quick < 25m', 'Low Calorie'];

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Tìm kiếm thực đơn'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nhập tên món ăn hoặc nguyên liệu...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (val) {
              Navigator.of(ctx).pop();
              if (val.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đang lọc thực đơn theo: "$val"')),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showScheduleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lịch Trình Thực Đơn Tuần',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Thứ 2 - Thứ 4: Tomato Chicken Stew\nThứ 5 - Thứ 6: Green Goddess Bowl\nCuối tuần: Berry Chia Yogurt Parfait',
              style: TextStyle(height: 1.6, fontSize: 14, color: AppTheme.charcoalInk),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Đã hiểu', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealPlansAsync = ref.watch(mealPlansProvider);

    return Scaffold(
      floatingActionButton: const FloatingCartButton(),
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'GreenCart',
          subtitle: 'Meal Planner',
        ),
        actions: [
          IconButton(
            tooltip: 'Search recipes',
            onPressed: () => _showSearchDialog(context),
            icon: const Icon(Icons.search, color: AppTheme.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(mealPlansProvider);
          return await ref.read(mealPlansProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          children: [
            Text(
              'Meal Planner',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Plan your week with fresh ingredients.',
              style: TextStyle(color: AppTheme.outline, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _RecipeSearchPill(onTap: () => _showSearchDialog(context)),
            const SizedBox(height: 14),
            _FilterChips(
              filters: _filters,
              selectedIndex: _selectedFilterIndex,
              onSelected: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilterIndex = idx);
              },
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Planned Meals',
              actionLabel: 'View Schedule',
              onAction: () => _showScheduleModal(context),
            ),
            const SizedBox(height: 14),
            const _PlannedMealStrip(),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Popular Recipes',
              actionLabel: 'See All',
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang hiển thị toàn bộ công thức nổi bật')),
                );
              },
            ),
            const SizedBox(height: 14),
            mealPlansAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
              error: (err, stack) => Center(child: Text('Lỗi tải thực đơn: $err')),
              data: (plans) {
                if (plans.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Chưa có thực đơn mẫu nào.'),
                    ),
                  );
                }

                var filteredPlans = plans;
                if (_selectedFilterIndex == 1) {
                  filteredPlans = plans.where((m) => m.minutes < 25).toList();
                } else if (_selectedFilterIndex == 2) {
                  filteredPlans = plans.where((m) => m.calories < 450).toList();
                }

                if (filteredPlans.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Không tìm thấy công thức phù hợp bộ lọc.'),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final meal in filteredPlans) ...[
                      _MealPlanCard(meal: meal),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            const _SmartSelectionCard(),
          ],
        ),
      ),
    );
  }
}

class _RecipeSearchPill extends StatelessWidget {
  const _RecipeSearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppTheme.outline, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Find recipes...',
                style: TextStyle(color: AppTheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return ActionChip(
            label: Text(filters[index]),
            backgroundColor: isSelected ? AppTheme.primary : AppTheme.succulentGreen,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            padding: EdgeInsets.zero,
            onPressed: () => onSelected(index),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}

class _PlannedMealStrip extends ConsumerWidget {
  const _PlannedMealStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlansAsync = ref.watch(mealPlansProvider);
    return mealPlansAsync.when(
      loading: () => const SizedBox(
        height: 126,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, st) => const SizedBox.shrink(),
      data: (mealPlans) {
        final planned = mealPlans.take(2).toList();
        if (planned.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: planned.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final meal = planned[index];
              return SizedBox(
                width: 220,
                child: OrganicCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    onTap: () => context.push(RecipeDetailScreen.pathFor(meal.id)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          meal.imageUrl.isNotEmpty
                              ? meal.imageUrl
                              : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.succulentGreen,
                            child: const Icon(Icons.restaurant, color: AppTheme.primary),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.charcoalInk.withValues(alpha: 0.72),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${meal.minutes} min',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard({required this.meal});

  final MealPlan meal;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => context.push(RecipeDetailScreen.pathFor(meal.id)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                meal.imageUrl.isNotEmpty
                    ? meal.imageUrl
                    : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                width: 82,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 82,
                  height: 82,
                  color: AppTheme.succulentGreen,
                  child: const Icon(Icons.restaurant, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${meal.minutes} min - ${meal.calories} cal',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartSelectionCard extends ConsumerStatefulWidget {
  const _SmartSelectionCard();

  @override
  ConsumerState<_SmartSelectionCard> createState() => _SmartSelectionCardState();
}

class _SmartSelectionCardState extends ConsumerState<_SmartSelectionCard> {
  bool _isAdding = false;

  Future<void> _handleAddAll() async {
    setState(() => _isAdding = true);
    HapticFeedback.mediumImpact();

    try {
      final productsAsync = ref.read(featuredProductsProvider);
      final products = productsAsync.valueOrNull ?? [];
      final toAdd = products.take(3).toList();

      for (final p in toAdd) {
        await ref.read(cartRepositoryProvider).addItem(productId: p.id, quantity: 1);
      }
      ref.invalidate(cartProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌿 Đã thêm gói nguyên liệu Smart Selection vào giỏ hàng!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm vào giỏ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      radius: AppTheme.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Smart Selection',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome, color: AppTheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          const _IngredientRow(name: 'Organic Pineapple', price: '\$3.50'),
          const _IngredientRow(name: 'Romaine Tomatoes', price: '\$1.27'),
          const _IngredientRow(name: 'Fresh Bean Sprouts', price: '\$1.80'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAdding ? null : _handleAddAll,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              icon: _isAdding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: Text(
                _isAdding ? 'Adding...' : 'Add All Selected to Cart - \$5.50',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.name, required this.price});

  final String name;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppTheme.charcoalInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: AppTheme.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
