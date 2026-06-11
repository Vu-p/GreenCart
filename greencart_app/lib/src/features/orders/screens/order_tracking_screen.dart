import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/core/widgets/pulse_dot.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/orders/data/orders_repository.dart';
import 'package:greencart_app/src/features/orders/screens/rating_review_screen.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({required this.orderId, super.key});

  static const routePath = '/orders/:id';

  static String pathFor(String orderId) => '/orders/$orderId';

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: MobilePageTitle(
          title: 'Order $orderId',
          subtitle: 'Live delivery tracking',
        ),
      ),
      body: orderState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 28),
          children: [
            OrganicStateMessage(
              icon: Icons.local_shipping_outlined,
              title: 'Could not load this order.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(orderDetailProvider(orderId)),
            ),
          ],
        ),
        data: (order) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            AnimatedEntrance(
              child: OrganicPromoBanner(
                eyebrow: order.status.toUpperCase(),
                title: 'Your order ${order.orderNumber} is ${order.status}.',
                subtitle: order.deliveryAddress,
                icon: Icons.local_shipping_outlined,
                color: AppTheme.deepForest,
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Progress'),
            const SizedBox(height: 12),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 120),
              child: _TimelineStep(
                title: 'Order confirmed',
                subtitle:
                    'Payment ${order.paymentStatus.toLowerCase()} and basket reserved.',
                state: _stateFor(order.status, 0),
              ),
            ),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 220),
              child: _TimelineStep(
                title: 'Packed fresh',
                subtitle: 'Cold-packed produce with substitution preferences.',
                state: _stateFor(order.status, 1),
              ),
            ),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 320),
              child: _TimelineStep(
                title: 'On route',
                subtitle: 'Driver will call at the gate.',
                state: _stateFor(order.status, 2),
              ),
            ),
            const SizedBox(height: 18),
            OrganicCard(
              radius: AppTheme.radiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  for (final item in order.items) ...[
                    Row(
                      children: [
                        Expanded(child: Text(item.productName)),
                        Text('x${item.quantity}'),
                        const SizedBox(width: 12),
                        Text(formatCurrency(item.lineTotal)),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(height: 26, color: AppTheme.mistGray),
                  Row(
                    children: [
                      const Text('Total'),
                      const Spacer(),
                      Text(
                        formatCurrency(order.total),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: order.status == 'Completed' && !order.hasReview
                        ? () =>
                              context.push(RatingReviewScreen.pathFor(order.id))
                        : null,
                    icon: const Icon(Icons.star_outline),
                    label: Text(
                      order.hasReview ? 'Review submitted' : 'Rate delivery',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TimelineState _stateFor(String status, int step) {
    final currentStep = switch (status) {
      'Pending' || 'Confirmed' => 0,
      'Packing' => 1,
      'Delivering' => 2,
      'Completed' => 3,
      _ => 0,
    };

    if (status == 'Cancelled') {
      return _TimelineState.pending;
    }

    if (currentStep > step) {
      return _TimelineState.done;
    }

    if (currentStep == step) {
      return _TimelineState.active;
    }

    return _TimelineState.pending;
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final _TimelineState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _TimelineMarker(state: state),
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

enum _TimelineState { done, active, pending }

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({required this.state});

  final _TimelineState state;

  @override
  Widget build(BuildContext context) {
    if (state == _TimelineState.active) {
      return const SizedBox(width: 28, height: 28, child: PulseDot(size: 12));
    }

    final done = state == _TimelineState.done;
    return CircleAvatar(
      radius: 14,
      backgroundColor: done ? AppTheme.primary : AppTheme.mistGray,
      child: Icon(
        done ? Icons.check : Icons.more_horiz,
        color: done ? Colors.white : AppTheme.outline,
        size: 16,
      ),
    );
  }
}
