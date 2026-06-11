import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/services/api_client.dart';
import 'package:greencart_app/src/features/checkout/models/checkout_preview.dart';
import 'package:greencart_app/src/features/orders/models/order_item.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(apiClientProvider));
});

final checkoutPreviewProvider = FutureProvider.autoDispose<CheckoutPreview>((
  ref,
) {
  return ref.watch(checkoutRepositoryProvider).preview();
});

class CheckoutRepository {
  CheckoutRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CheckoutPreview> preview() async {
    final response = await _apiClient.post(
      '/api/checkout/preview',
      authorized: true,
    );
    return CheckoutPreview.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderItem> checkout({
    required String deliveryAddress,
    String? deliveryPhone,
    String? substitutionPreference,
  }) async {
    final response = await _apiClient.post(
      '/api/checkout',
      authorized: true,
      data: {
        'deliveryAddress': deliveryAddress,
        'deliveryPhone': deliveryPhone,
        'substitutionPreference': substitutionPreference,
      },
    );
    return OrderItem.fromJson(response.data as Map<String, dynamic>);
  }
}
