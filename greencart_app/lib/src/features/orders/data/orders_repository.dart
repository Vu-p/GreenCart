import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/services/api_client.dart';
import 'package:greencart_app/src/features/orders/models/order_item.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});

final ordersProvider = FutureProvider.autoDispose<List<OrderItem>>((ref) {
  return ref.watch(ordersRepositoryProvider).getOrders();
});

final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderItem, String>((ref, orderId) {
      return ref.watch(ordersRepositoryProvider).getOrder(orderId);
    });

class OrdersRepository {
  OrdersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<OrderItem>> getOrders() async {
    final response = await _apiClient.get('/api/orders', authorized: true);
    return (response.data as List<dynamic>)
        .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderItem> getOrder(String orderId) async {
    final response = await _apiClient.get(
      '/api/orders/$orderId',
      authorized: true,
    );
    return OrderItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderItem> cancelOrder(String orderId) async {
    final response = await _apiClient.post(
      '/api/orders/$orderId/cancel',
      authorized: true,
    );
    return OrderItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? comment,
    List<Map<String, dynamic>>? productReviews,
  }) async {
    await _apiClient.post(
      '/api/orders/$orderId/review',
      authorized: true,
      data: {
        'rating': rating,
        'comment': comment,
        'productReviews': productReviews ?? [],
      },
    );
  }
}
