import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/orders/data/orders_repository.dart';
import 'package:greencart_app/src/features/orders/screens/orders_screen.dart';

class RatingReviewScreen extends ConsumerStatefulWidget {
  const RatingReviewScreen({required this.orderId, super.key});

  static const routePath = '/orders/:id/review';

  static String pathFor(String orderId) => '/orders/$orderId/review';

  final String orderId;

  @override
  ConsumerState<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends ConsumerState<RatingReviewScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  final Map<String, int> _productRatings = {};
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final productReviews = _productRatings.entries
          .map((e) => {'productId': e.key, 'rating': e.value})
          .toList();

      await ref.read(ordersRepositoryProvider).submitReview(
            orderId: widget.orderId,
            rating: _rating,
            comment: _commentController.text,
            productReviews: productReviews,
          );

      ref.invalidate(ordersProvider);
      ref.invalidate(orderDetailProvider(widget.orderId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá đơn hàng!')),
        );
        context.go(OrdersScreen.routePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi đánh giá: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: MobilePageTitle(
          title: 'Rate Order',
          subtitle: 'Order #${widget.orderId.substring(0, 8)}',
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải đơn hàng: $err')),
        data: (order) {
          final products = order.items.where((i) => i.productId != null).toList();

          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              OrganicCard(
                radius: AppTheme.radiusLg,
                child: Column(
                  children: [
                    Text(
                      'How was your delivery?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          onPressed: () => setState(() => _rating = star),
                          icon: Icon(
                            star <= _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'Share notes about freshness, packing, or delivery',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (products.isNotEmpty) ...[
                Text(
                  'Rate items in your order',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
              ],
              for (final product in products) ...[
                OrganicCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_outlined, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          product.productName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          final pStar = index + 1;
                          final currentRating = _productRatings[product.productId!] ?? 5;
                          return InkWell(
                            onTap: () => setState(() => _productRatings[product.productId!] = pStar),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                pStar <= currentRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('Submit Review'),
              ),
            ],
          );
        },
      ),
    );
  }
}
