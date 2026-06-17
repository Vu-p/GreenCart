class ProductReview {
  const ProductReview({
    required this.id,
    required this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] as String,
      productId: json['productId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
