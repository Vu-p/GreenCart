import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/services/api_client.dart';
import 'package:greencart_app/src/features/meal_planner/models/meal_plan.dart';

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository(ref.watch(apiClientProvider));
});

final mealPlansProvider = FutureProvider<List<MealPlan>>((ref) {
  return ref.watch(mealPlanRepositoryProvider).getMealPlans();
});

final mealPlanDetailProvider = FutureProvider.family<MealPlan, String>((
  ref,
  id,
) {
  return ref.watch(mealPlanRepositoryProvider).getMealPlan(id);
});

class MealPlanRepository {
  MealPlanRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MealPlan>> getMealPlans() async {
    final response = await _apiClient.get('/api/meal-plans');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => MealPlan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MealPlan> getMealPlan(String id) async {
    final response = await _apiClient.get('/api/meal-plans/$id');
    return MealPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> addIngredientsToCart(String id, {List<String>? ingredientIds}) async {
    await _apiClient.post(
      '/api/meal-plans/$id/cart-items',
      authorized: true,
      data: {
        'addAll': ingredientIds == null || ingredientIds.isEmpty,
        'ingredientIds': ingredientIds ?? [],
      },
    );
  }
}
