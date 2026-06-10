class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.isOrganic,
    required this.isDeal,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final String categoryId;
  final String categoryName;
  final bool isOrganic;
  final bool isDeal;

  bool get inStock => stock > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      imageUrl: json['imageUrl'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      isOrganic: json['isOrganic'] as bool,
      isDeal: json['isDeal'] as bool,
    );
  }
}
