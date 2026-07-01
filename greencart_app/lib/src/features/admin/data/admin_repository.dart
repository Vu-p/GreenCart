import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../catalog/models/category.dart';
import '../../catalog/models/product.dart';
import '../../orders/models/order_item.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

final adminOrdersProvider = FutureProvider.autoDispose<List<OrderItem>>((ref) {
  return ref.watch(adminRepositoryProvider).getOrders();
});

final adminProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(adminRepositoryProvider).getProducts();
});

class AdminRepository {
  AdminRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<OrderItem>> getOrders() async {
    final response = await _apiClient.get('/api/admin/orders', authorized: true);
    final list = response.data as List<dynamic>;
    return list
        .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderItem> updateOrderStatus(String orderId, String status) async {
    final response = await _apiClient.put(
      '/api/admin/orders/$orderId/status',
      authorized: true,
      data: {'status': status},
    );
    return OrderItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Product>> getProducts() async {
    final response = await _apiClient.get('/api/admin/products', authorized: true);
    final list = response.data as List<dynamic>;
    return list
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String imageUrl,
    required String categoryId,
    required bool isOrganic,
    required bool isDeal,
  }) async {
    final response = await _apiClient.post(
      '/api/admin/products',
      authorized: true,
      data: {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
        'categoryId': categoryId,
        'isOrganic': isOrganic,
        'isDeal': isDeal,
      },
    );
    return Product.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Product> updateProduct(
    String id, {
    required String name,
    required String description,
    required double price,
    required int stock,
    required String imageUrl,
    required String categoryId,
    required bool isOrganic,
    required bool isDeal,
  }) async {
    final response = await _apiClient.put(
      '/api/admin/products/$id',
      authorized: true,
      data: {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
        'categoryId': categoryId,
        'isOrganic': isOrganic,
        'isDeal': isDeal,
      },
    );
    return Product.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) async {
    await _apiClient.delete('/api/admin/products/$id', authorized: true);
  }

  Future<GroceryCategory> createCategory({
    required String name,
    String? imageUrl,
  }) async {
    final response = await _apiClient.post(
      '/api/admin/categories',
      authorized: true,
      data: {
        'name': name,
        'imageUrl': imageUrl,
      },
    );
    return GroceryCategory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroceryCategory> updateCategory(
    String id, {
    required String name,
    String? imageUrl,
  }) async {
    final response = await _apiClient.put(
      '/api/admin/categories/$id',
      authorized: true,
      data: {
        'name': name,
        'imageUrl': imageUrl,
      },
    );
    return GroceryCategory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _apiClient.delete('/api/admin/categories/$id', authorized: true);
  }

  Future<void> proposeSubstitution({
    required String orderId,
    required String orderItemId,
    required String originalProductId,
    required String replacementProductId,
    String? note,
  }) async {
    await _apiClient.post(
      '/api/admin/orders/$orderId/substitutions',
      authorized: true,
      data: {
        'orderItemId': orderItemId,
        'originalProductId': originalProductId,
        'replacementProductId': replacementProductId,
        'note': note,
      },
    );
  }
}
