import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/orders/screens/rating_review_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({required this.orderId, super.key});

  static const routePath = '/orders/:id';

  static String pathFor(String orderId) => '/orders/$orderId';

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MobilePageTitle(
          title: 'Order $orderId',
          subtitle: 'Live delivery tracking',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const OrganicPromoBanner(
            eyebrow: 'ON ROUTE',
            title: 'Your produce is being packed.',
            subtitle: 'Expected today between 5:00 - 7:00 PM.',
            icon: Icons.local_shipping_outlined,
            color: AppTheme.deepForest,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Progress'),
          const SizedBox(height: 12),
          const _TimelineStep(
            title: 'Order confirmed',
            subtitle: 'Payment received and basket reserved.',
            done: true,
          ),
          const _TimelineStep(
            title: 'Packed fresh',
            subtitle: 'Cold-packed produce with substitution preferences.',
            done: true,
          ),
          const _TimelineStep(
            title: 'On route',
            subtitle: 'Driver will call at the gate.',
            done: false,
          ),
          const SizedBox(height: 18),
          OrganicCard(
            radius: AppTheme.radiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery notes',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave at reception if unavailable. Keep chilled items in insulated bag.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go(RatingReviewScreen.pathFor(orderId)),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Rate after delivery'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.done,
  });

  final String title;
  final String subtitle;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: done ? AppTheme.primary : AppTheme.mistGray,
              child: Icon(
                done ? Icons.check : Icons.more_horiz,
                color: done ? Colors.white : AppTheme.outline,
                size: 16,
              ),
            ),
            Container(width: 2, height: 58, color: AppTheme.mistGray),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OrganicCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
