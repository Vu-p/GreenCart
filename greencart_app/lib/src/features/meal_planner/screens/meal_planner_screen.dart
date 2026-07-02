import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/meal_planner/data/meal_plan_repository.dart';
import 'package:greencart_app/src/features/meal_planner/data/mock_meal_plans.dart';
import 'package:greencart_app/src/features/meal_planner/models/meal_plan.dart';
import 'package:greencart_app/src/features/meal_planner/screens/recipe_detail_screen.dart';

class MealPlannerScreen extends ConsumerWidget {
  const MealPlannerScreen({super.key});

  static const routePath = '/meal-planner';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlansAsync = ref.watch(mealPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'GreenCart',
          subtitle: 'Meal Planner',
        ),
        actions: [
          IconButton(
            tooltip: 'Search recipes',
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppTheme.primary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
          _RecipeSearchPill(onTap: () {}),
          const SizedBox(height: 14),
          const _FilterChips(),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Planned Meals',
            actionLabel: 'View Schedule',
            onAction: () {},
          ),
          const SizedBox(height: 14),
          const _PlannedMealStrip(),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Popular Recipes',
            actionLabel: 'See All',
            onAction: () {},
          ),
          const SizedBox(height: 14),
          mealPlansAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (err, stack) => Center(child: Text('Lỗi tải thực đơn: $err')),
            data: (plans) {
              final list = plans.isNotEmpty ? plans : mealPlans;
              return Column(
                children: [
                  for (final meal in list) ...[
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
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    const filters = ['All Recipes', 'Quick & Easy', 'Healthy'];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Chip(
          label: Text(filters[index]),
          backgroundColor: index == 0
              ? AppTheme.primary
              : AppTheme.succulentGreen,
          labelStyle: TextStyle(
            color: index == 0 ? Colors.white : AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          padding: EdgeInsets.zero,
        ),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}

class _PlannedMealStrip extends StatelessWidget {
  const _PlannedMealStrip();

  @override
  Widget build(BuildContext context) {
    final planned = mealPlans.take(2).toList();
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: planned.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final meal = planned[index];
          return InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: () => context.push(RecipeDetailScreen.pathFor(meal.id)),
            child: SizedBox(
              width: 154,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(_imageFor(meal.id), fit: BoxFit.cover),
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
                _imageFor(meal.id),
                width: 82,
                height: 82,
                fit: BoxFit.cover,
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

class _SmartSelectionCard extends StatelessWidget {
  const _SmartSelectionCard();

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
          ElevatedButton(
            onPressed: () {},
            child: const Text('Add All Selected to Cart - \$5.50'),
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

String _imageFor(String id) {
  switch (id) {
    case 'tomato-chicken':
      return 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=900';
    case 'berry-yogurt':
      return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=900';
    case 'green-bowl':
    default:
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=900';
  }
}
