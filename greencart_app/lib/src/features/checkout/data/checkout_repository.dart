import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/services/api_client.dart';
import 'package:greencart_app/src/features/checkout/models/checkout_payment.dart';
import 'package:greencart_app/src/features/checkout/models/checkout_preview.dart';

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

  Future<CheckoutPayment> checkout({
    required String deliveryAddress,
    String? deliveryPhone,
    String? deliverySlot,
    String? substitutionPreference,
  }) async {
    final response = await _apiClient.post(
      '/api/checkout',
      authorized: true,
      data: {
        'deliveryAddress': deliveryAddress,
        'deliveryPhone': deliveryPhone,
        'deliverySlot': deliverySlot,
        'substitutionPreference': substitutionPreference,
      },
    );
    return CheckoutPayment.fromJson(response.data as Map<String, dynamic>);
  }
}
