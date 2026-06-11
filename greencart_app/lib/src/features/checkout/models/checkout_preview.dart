import 'package:greencart_app/src/features/cart/models/cart_item.dart';

class CheckoutPreview {
  const CheckoutPreview({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.deliveryAddress,
    this.deliveryPhone,
    this.substitutionPreference,
  });

  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? substitutionPreference;

  factory CheckoutPreview.fromJson(Map<String, dynamic> json) {
    return CheckoutPreview(
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      deliveryAddress: json['deliveryAddress'] as String?,
      deliveryPhone: json['deliveryPhone'] as String?,
      substitutionPreference: json['substitutionPreference'] as String?,
    );
  }
}
