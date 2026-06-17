import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/features/orders/data/orders_repository.dart';
import 'package:greencart_app/src/features/orders/models/order_item.dart';
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
  final _commentController = TextEditingController();
  final Map<String, int> _productRatings = {};
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: MobilePageTitle(
          title: 'Rate Order',
          subtitle: 'Order ${widget.orderId}',
        ),
      ),
      body: orderState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 28),
          children: [
            OrganicStateMessage(
              icon: Icons.rate_review_outlined,
              title: 'Could not load this order.',
              actionLabel: 'Retry',
              onAction: () =>
                  ref.invalidate(orderDetailProvider(widget.orderId)),
            ),
          ],
        ),
        data: (order) => _ReviewForm(
          order: order,
          rating: _rating,
          productRatings: _productRatings,
          commentController: _commentController,
          submitting: _submitting,
          onRatingChanged: (rating) => setState(() => _rating = rating),
          onProductRatingChanged: (productId, rating) {
            setState(() => _productRatings[productId] = rating);
          },
          onSubmit: () => _submit(order),
        ),
      ),
    );
  }

  Future<void> _submit(OrderItem order) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final ratings = <String, int>{};
    for (final item in order.items) {
      final productId = item.productId;
      if (productId != null) {
        ratings[productId] = _productRatings[productId] ?? _rating;
      }
    }

    setState(() => _submitting = true);
    try {
      await ref.read(ordersRepositoryProvider).submitReview(
            orderId: order.id,
            rating: _rating,
            comment: _commentController.text,
            productRatings: ratings,
          );
      ref
        ..invalidate(ordersProvider)
        ..invalidate(orderDetailProvider(order.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks, your review was submitted.')),
        );
        context.go(OrdersScreen.routePath);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit review. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.order,
    required this.rating,
    required this.productRatings,
    required this.commentController,
    required this.submitting,
    required this.onRatingChanged,
    required this.onProductRatingChanged,
    required this.onSubmit,
  });

  final OrderItem order;
  final int rating;
  final Map<String, int> productRatings;
  final TextEditingController commentController;
  final bool submitting;
  final ValueChanged<int> onRatingChanged;
  final void Function(String productId, int rating) onProductRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final reviewableItems = order.items
        .where((item) => item.productId != null)
        .toList(growable: false);

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
              _StarRating(value: rating, onChanged: onRatingChanged, size: 38),
              const SizedBox(height: 18),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Share notes about freshness, packing, or delivery',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final item in reviewableItems) ...[
          OrganicCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Image.network(
                    item.imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 44,
                      height: 44,
                      color: AppTheme.succulentGreen,
                      child: const Icon(
                        Icons.eco_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _StarRating(
                  value: productRatings[item.productId] ?? rating,
                  onChanged: (value) =>
                      onProductRatingChanged(item.productId!, value),
                  size: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(submitting ? 'Submitting...' : 'Submit Review'),
        ),
      ],
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.value,
    required this.onChanged,
    required this.size,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 1; index <= 5; index++)
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints.tightFor(
              width: size + 8,
              height: size + 8,
            ),
            padding: EdgeInsets.zero,
            onPressed: () => onChanged(index),
            icon: Icon(
              index <= value
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: index <= value
                  ? AppTheme.ripenedOrange
                  : AppTheme.outline,
              size: size,
            ),
          ),
      ],
    );
  }
}
