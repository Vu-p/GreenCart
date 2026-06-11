import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/services/api_client.dart';
import 'package:greencart_app/src/features/cart/models/cart_item.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(apiClientProvider));
});

final cartProvider = FutureProvider.autoDispose<Cart>((ref) {
  return ref.watch(cartRepositoryProvider).getCart();
});

class CartRepository {
  CartRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Cart> getCart() async {
    final response = await _apiClient.get('/api/cart', authorized: true);
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> addItem({
    required String productId,
    required int quantity,
  }) async {
    final response = await _apiClient.post(
      '/api/cart/items',
      authorized: true,
      data: {'productId': productId, 'quantity': quantity},
    );
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> updateItem({
    required String productId,
    required int quantity,
  }) async {
    final response = await _apiClient.put(
      '/api/cart/items/$productId',
      authorized: true,
      data: {'quantity': quantity},
    );
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> removeItem(String productId) async {
    final response = await _apiClient.delete(
      '/api/cart/items/$productId',
      authorized: true,
    );
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> clear() async {
    final response = await _apiClient.delete('/api/cart', authorized: true);
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }
}
