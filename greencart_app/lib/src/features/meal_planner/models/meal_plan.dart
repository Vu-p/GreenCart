import 'package:flutter/material.dart';

class MealPlan {
  const MealPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.calories,
    required this.ingredients,
    required this.steps,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final int minutes;
  final int calories;
  final List<String> ingredients;
  final List<String> steps;
  final IconData icon;
  final Color color;
}
