import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/orders/screens/orders_screen.dart';

class RatingReviewScreen extends StatelessWidget {
  const RatingReviewScreen({required this.orderId, super.key});

  static const routePath = '/orders/:id/review';

  static String pathFor(String orderId) => '/orders/$orderId/review';

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MobilePageTitle(title: 'Rate Order', subtitle: 'Order $orderId'),
      ),
      body: ListView(
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Star(active: true),
                    _Star(active: true),
                    _Star(active: true),
                    _Star(active: true),
                    _Star(active: false),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
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
          for (final product in const [
            'Organic Spinach',
            'Avocado Pack',
            'Greek Yogurt',
          ]) ...[
            OrganicCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.eco_outlined, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const Icon(
                    Icons.thumb_up_alt_outlined,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              context.go(OrdersScreen.routePath);
            },
            icon: const Icon(Icons.send_outlined),
            label: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Icon(
      active ? Icons.star_rounded : Icons.star_outline_rounded,
      color: active ? AppTheme.ripenedOrange : AppTheme.outline,
      size: 38,
    );
  }
}
