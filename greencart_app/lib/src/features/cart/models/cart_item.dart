class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.stock,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final int stock;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lineTotal: (json['lineTotal'] as num).toDouble(),
      stock: json['stock'] as int,
    );
  }
}

class Cart {
  const Cart({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}
