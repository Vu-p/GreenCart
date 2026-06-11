import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/meal_planner/data/mock_meal_plans.dart';
import 'package:greencart_app/src/features/meal_planner/models/meal_plan.dart';
import 'package:greencart_app/src/features/meal_planner/screens/recipe_detail_screen.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  static const routePath = '/meal-planner';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Meal Planner',
          subtitle: 'Plan meals around fresh groceries',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const OrganicPromoBanner(
            eyebrow: 'THIS WEEK',
            title: '3 balanced meals from your GreenCart staples.',
            subtitle: 'Auto-build a basket from selected recipes.',
            icon: Icons.calendar_month_outlined,
            color: AppTheme.deepForest,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recommended Recipes'),
          const SizedBox(height: 14),
          for (final meal in mealPlans) ...[
            _MealPlanCard(meal: meal),
            const SizedBox(height: 12),
          ],
        ],
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
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: meal.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(meal.icon, color: AppTheme.primary, size: 32),
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
            const Icon(Icons.chevron_right, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }
}
