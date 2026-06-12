import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/cart/screens/cart_screen.dart';
import 'package:greencart_app/src/features/meal_planner/data/mock_meal_plans.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  static const routePath = '/meal-planner/recipes/:id';

  static String pathFor(String recipeId) => '/meal-planner/recipes/$recipeId';

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final meal = mealPlanById(recipeId);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 320,
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
                        AppTheme.charcoalInk.withValues(alpha: 0.12),
                        AppTheme.charcoalInk.withValues(alpha: 0.74),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: IconButton(
                          tooltip: 'Back',
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${meal.minutes} min - ${meal.calories} cal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        meal.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              children: [
                OrganicCard(
                  color: AppTheme.succulentGreen,
                  radius: AppTheme.radiusLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About this recipe',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.deepForest),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal.subtitle,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OrganicCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.ripenedOrange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add ingredients individually or add everything to your cart in one tap.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionHeader(title: 'Ingredients'),
                const SizedBox(height: 12),
                for (final ingredient in meal.ingredients) ...[
                  _ChecklistRow(label: ingredient),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
                const SectionHeader(title: 'Prep Steps'),
                const SizedBox(height: 12),
                for (var i = 0; i < meal.steps.length; i++) ...[
                  _StepRow(number: i + 1, text: meal.steps[i]),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => context.go(CartScreen.routePath),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Add All to Cart'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.succulentGreen,
            child: Icon(Icons.add, color: AppTheme.primary, size: 18),
          ),
        ],
      ),
    );
  }
}

String _imageFor(String id) {
  switch (id) {
    case 'tomato-chicken':
      return 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=1100';
    case 'berry-yogurt':
      return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=1100';
    case 'green-bowl':
    default:
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=1100';
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppTheme.succulentGreen,
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
