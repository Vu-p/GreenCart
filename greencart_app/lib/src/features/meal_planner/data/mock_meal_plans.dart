import 'package:flutter/material.dart';

import '../models/meal_plan.dart';

const mealPlans = [
  MealPlan(
    id: 'green-bowl',
    title: 'Green Power Bowl',
    subtitle: 'Spinach, avocado, brown rice, and yogurt dressing.',
    minutes: 22,
    calories: 520,
    ingredients: [
      'Organic Spinach',
      'Avocado Pack',
      'Brown Rice',
      'Greek Yogurt',
    ],
    steps: [
      'Warm cooked brown rice with a pinch of salt.',
      'Layer spinach, sliced avocado, and tomatoes in a bowl.',
      'Whisk yogurt with lemon, pepper, and olive oil.',
      'Finish with dressing and serve fresh.',
    ],
    icon: Icons.rice_bowl_outlined,
    color: Color(0xFFE1F4EA),
  ),
  MealPlan(
    id: 'tomato-chicken',
    title: 'Tomato Chicken Plate',
    subtitle: 'Lean chicken breast with vine tomatoes and greens.',
    minutes: 30,
    calories: 610,
    ingredients: ['Chicken Breast', 'Vine Tomatoes', 'Organic Spinach'],
    steps: [
      'Season chicken breast and sear until golden.',
      'Roast tomatoes until they soften and release juices.',
      'Wilt spinach in the pan for one minute.',
      'Plate together with fresh herbs.',
    ],
    icon: Icons.dinner_dining_outlined,
    color: Color(0xFFFFF1D6),
  ),
  MealPlan(
    id: 'berry-yogurt',
    title: 'Berry Yogurt Crunch',
    subtitle: 'Greek yogurt, strawberries, oats, and honey.',
    minutes: 8,
    calories: 340,
    ingredients: ['Greek Yogurt', 'Strawberries', 'Brown Rice'],
    steps: [
      'Spoon yogurt into a chilled bowl.',
      'Slice strawberries and layer over the top.',
      'Add toasted grains or granola for crunch.',
      'Drizzle lightly with honey.',
    ],
    icon: Icons.icecream_outlined,
    color: Color(0xFFFFE8EC),
  ),
];

MealPlan mealPlanById(String id) {
  return mealPlans.firstWhere(
    (meal) => meal.id == id,
    orElse: () => mealPlans.first,
  );
}
