class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.deliveryPhone,
    this.substitutionPreference,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    required this.hasReview,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String deliveryAddress;
  final String? deliveryPhone;
  final String? substitutionPreference;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final List<OrderLineItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasReview;

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);
  bool get active => status != 'Completed' && status != 'Cancelled';

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      deliveryAddress: json['deliveryAddress'] as String,
      deliveryPhone: json['deliveryPhone'] as String?,
      substitutionPreference: json['substitutionPreference'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      hasReview: json['hasReview'] as bool,
    );
  }
}

class OrderLineItem {
  const OrderLineItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String id;
  final String? productId;
  final String productName;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      id: json['id'] as String,
      productId: json['productId'] as String?,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }
}
