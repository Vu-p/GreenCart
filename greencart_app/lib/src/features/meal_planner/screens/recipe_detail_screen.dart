import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/cart/screens/cart_screen.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';
import 'package:greencart_app/src/features/catalog/models/product.dart';
import 'package:greencart_app/src/features/meal_planner/data/meal_plan_repository.dart';
import 'package:greencart_app/src/features/meal_planner/data/mock_meal_plans.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  static const routePath = '/meal-planner/recipes/:id';

  static String pathFor(String recipeId) => '/meal-planner/recipes/$recipeId';

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  final Set<String> _addingProductIds = {};
  final Set<String> _addedProductIds = {};
  bool _isAddingAll = false;

  Future<void> _addIngredient(Product product) async {
    if (_addingProductIds.contains(product.id) || !product.inStock) {
      return;
    }

    setState(() => _addingProductIds.add(product.id));
    try {
      await ref
          .read(cartRepositoryProvider)
          .addItem(productId: product.id, quantity: 1);
      ref.invalidate(cartProvider);
      if (!mounted) {
        return;
      }
      setState(() => _addedProductIds.add(product.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added to your cart.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cartErrorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _addingProductIds.remove(product.id));
      }
    }
  }

  Future<void> _addAllIngredients(List<Product> products) async {
    if (_isAddingAll) {
      return;
    }

    final availableProducts = products
        .where(
          (product) =>
              product.inStock && !_addedProductIds.contains(product.id),
        )
        .toList();
    if (availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All available ingredients are already in your cart.'),
        ),
      );
      return;
    }

    setState(() => _isAddingAll = true);
    try {
      try {
        await ref.read(mealPlanRepositoryProvider).addIngredientsToCart(widget.recipeId);
      } catch (_) {
        for (final product in availableProducts) {
          await ref
              .read(cartRepositoryProvider)
              .addItem(productId: product.id, quantity: 1);
        }
      }
      ref.invalidate(cartProvider);
      if (mounted) {
        context.go(CartScreen.routePath);
      }
    } catch (error) {
      ref.invalidate(cartProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cartErrorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = mealPlanById(widget.recipeId);
    final productsState = ref.watch(featuredProductsProvider);

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
                productsState.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => OrganicStateMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load ingredient products.',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(featuredProductsProvider),
                  ),
                  data: (products) {
                    final productsByName = {
                      for (final product in products)
                        product.name.toLowerCase(): product,
                    };
                    final ingredients = meal.ingredients
                        .map((name) => productsByName[name.toLowerCase()])
                        .whereType<Product>()
                        .toList();
                    final missingNames = meal.ingredients
                        .where(
                          (name) => productsByName[name.toLowerCase()] == null,
                        )
                        .toList();

                    return Column(
                      children: [
                        for (final product in ingredients) ...[
                          _ChecklistRow(
                            product: product,
                            isAdding:
                                _addingProductIds.contains(product.id) ||
                                _isAddingAll,
                            isAdded: _addedProductIds.contains(product.id),
                            onAdd: () => _addIngredient(product),
                          ),
                          const SizedBox(height: 10),
                        ],
                        for (final name in missingNames) ...[
                          _UnavailableIngredientRow(label: name),
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
                          onPressed: ingredients.isEmpty || _isAddingAll
                              ? null
                              : () => _addAllIngredients(ingredients),
                          icon: _isAddingAll
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.shopping_cart_outlined),
                          label: Text(
                            _isAddingAll
                                ? 'Adding Ingredients...'
                                : 'Add All to Cart',
                          ),
                        ),
                      ],
                    );
                  },
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
  const _ChecklistRow({
    required this.product,
    required this.isAdding,
    required this.isAdded,
    required this.onAdd,
  });

  final Product product;
  final bool isAdding;
  final bool isAdded;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  product.inStock
                      ? '${product.stock} in stock'
                      : 'Out of stock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: product.inStock
                        ? AppTheme.outline
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: isAdded ? 'Added to cart' : 'Add ingredient to cart',
            onPressed: product.inStock && !isAdding ? onAdd : null,
            icon: isAdding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isAdded ? Icons.check : Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

class _UnavailableIngredientRow extends StatelessWidget {
  const _UnavailableIngredientRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.outline),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          const Text(
            'Unavailable',
            style: TextStyle(
              color: AppTheme.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _cartErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('401')) {
    return 'Please sign in before adding ingredients to your cart.';
  }
  if (text.contains('exceeds available stock')) {
    return 'One ingredient exceeds its available stock.';
  }
  if (text.contains('out of stock')) {
    return 'One ingredient is out of stock.';
  }
  return 'Could not update your cart. Please try again.';
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
