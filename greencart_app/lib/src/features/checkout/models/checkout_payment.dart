import 'package:greencart_app/src/features/orders/models/order_item.dart';

class CheckoutPayment {
  const CheckoutPayment({
    required this.order,
    required this.checkoutUrl,
    required this.paymentLinkId,
    required this.qrCode,
    required this.payOsOrderCode,
  });

  final OrderItem order;
  final String checkoutUrl;
  final String paymentLinkId;
  final String qrCode;
  final int payOsOrderCode;

  factory CheckoutPayment.fromJson(Map<String, dynamic> json) {
    return CheckoutPayment(
      order: OrderItem.fromJson(json['order'] as Map<String, dynamic>),
      checkoutUrl: json['checkoutUrl'] as String,
      paymentLinkId: json['paymentLinkId'] as String,
      qrCode: json['qrCode'] as String? ?? '',
      payOsOrderCode: json['payOsOrderCode'] as int,
    );
  }
}
