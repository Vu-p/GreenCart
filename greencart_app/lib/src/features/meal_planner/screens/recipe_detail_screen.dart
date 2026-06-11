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
      appBar: AppBar(title: Text(meal.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: meal.color,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(meal.icon, color: AppTheme.primary, size: 78),
          ),
          const SizedBox(height: 20),
          OrganicCard(
            radius: AppTheme.radiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  meal.subtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('${meal.minutes} min')),
                    Chip(label: Text('${meal.calories} calories')),
                    const Chip(label: Text('Organic ready')),
                  ],
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
            label: const Text('Add Ingredients to Cart'),
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
        ],
      ),
    );
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
