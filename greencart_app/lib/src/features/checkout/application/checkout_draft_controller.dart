import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checkout_preview.dart';
import '../models/delivery_slot.dart';

class CheckoutDraft {
  const CheckoutDraft({
    required this.deliveryAddress,
    this.deliveryPhone,
    this.deliverySlot,
  });

  final String deliveryAddress;
  final String? deliveryPhone;
  final DeliverySlot? deliverySlot;

  CheckoutDraft copyWith({
    String? deliveryAddress,
    String? deliveryPhone,
    bool clearDeliveryPhone = false,
    DeliverySlot? deliverySlot,
  }) {
    return CheckoutDraft(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPhone: clearDeliveryPhone
          ? null
          : deliveryPhone ?? this.deliveryPhone,
      deliverySlot: deliverySlot ?? this.deliverySlot,
    );
  }
}

final checkoutDraftProvider =
    StateNotifierProvider<CheckoutDraftController, CheckoutDraft?>(
      (ref) => CheckoutDraftController(),
    );

class CheckoutDraftController extends StateNotifier<CheckoutDraft?> {
  CheckoutDraftController() : super(null);

  void initialize(CheckoutPreview preview) {
    state ??= CheckoutDraft(
      deliveryAddress:
          preview.deliveryAddress ??
          '42 Green Valley Rd, Ho Chi Minh City, Vietnam',
      deliveryPhone: preview.deliveryPhone,
    );
  }

  void updateAddress({required String address, String? phone}) {
    final current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(
      deliveryAddress: address.trim(),
      deliveryPhone: phone?.trim(),
      clearDeliveryPhone: phone == null || phone.trim().isEmpty,
    );
  }

  void selectSlot(DeliverySlot slot) {
    final current = state;
    if (current != null) {
      state = current.copyWith(deliverySlot: slot);
    }
  }

  void clear() {
    state = null;
  }
}
