import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_client.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(apiClientProvider));
});

final categoriesProvider = FutureProvider<List<GroceryCategory>>((ref) {
  return ref.watch(productRepositoryProvider).getCategories();
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getProducts();
});

final productDetailProvider =
    FutureProvider.family<Product, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).getProduct(productId);
});

class ProductRepository {
  ProductRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<GroceryCategory>> getCategories() async {
    final response = await _apiClient.get('/api/categories');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => GroceryCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> getProducts({
    String? keyword,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParameters['keyword'] = keyword.trim();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParameters['categoryId'] = categoryId;
    }
    if (minPrice != null) {
      queryParameters['minPrice'] = minPrice;
    }
    if (maxPrice != null) {
      queryParameters['maxPrice'] = maxPrice;
    }

    final response = await _apiClient.get(
      '/api/products',
      queryParameters: queryParameters,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProduct(String productId) async {
    final response = await _apiClient.get('/api/products/$productId');
    return Product.fromJson(response.data as Map<String, dynamic>);
  }
}
