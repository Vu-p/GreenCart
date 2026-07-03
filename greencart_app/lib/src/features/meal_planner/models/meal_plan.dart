import 'package:flutter/material.dart';

class MealIngredientItem {
  const MealIngredientItem({
    required this.id,
    required this.name,
    required this.quantityLabel,
    required this.productId,
    required this.unitPrice,
    required this.imageUrl,
    required this.stock,
  });

  final String id;
  final String name;
  final String quantityLabel;
  final String productId;
  final double unitPrice;
  final String imageUrl;
  final int stock;

  factory MealIngredientItem.fromJson(Map<String, dynamic> json) {
    return MealIngredientItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantityLabel: json['quantityLabel'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}

class MealPlan {
  const MealPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.minutes,
    required this.calories,
    required this.ingredients,
    required this.ingredientItems,
    required this.steps,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final int minutes;
  final int calories;
  final List<String> ingredients;
  final List<MealIngredientItem> ingredientItems;
  final List<String> steps;
  final IconData icon;
  final Color color;

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as List<dynamic>? ?? [];
    final items = <MealIngredientItem>[];
    final strings = <String>[];

    for (final item in rawIngredients) {
      if (item is Map<String, dynamic>) {
        final parsed = MealIngredientItem.fromJson(item);
        items.add(parsed);
        strings.add('${parsed.name} (${parsed.quantityLabel})');
      } else if (item is String) {
        strings.add(item);
      }
    }

    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    final stepsList = rawSteps.map((e) => e.toString()).toList();

    return MealPlan(
      id: json['slug'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 30,
      calories: (json['calories'] as num?)?.toInt() ?? 500,
      ingredients: strings,
      ingredientItems: items,
      steps: stepsList,
      icon: Icons.restaurant_menu_outlined,
      color: const Color(0xFFE1F4EA),
    );
  }
}
