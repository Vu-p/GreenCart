import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/floating_icon_badge.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/catalog/screens/home_screen.dart';
import 'package:greencart_app/src/features/orders/screens/order_tracking_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  static const routePath = '/checkout/success';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
          children: [
            const Center(
              child: FloatingIconBadge(
                icon: Icons.check_circle,
                size: 108,
                iconSize: 60,
              ),
            ),
            const SizedBox(height: 24),
            const AnimatedEntrance(
              delay: Duration(milliseconds: 120),
              child: Text(
                'Payment Confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.charcoalInk,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const AnimatedEntrance(
              delay: Duration(milliseconds: 220),
              child: Text(
                'Your GreenCart order is being packed for delivery today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.outline,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const AnimatedEntrance(
              delay: Duration(milliseconds: 340),
              child: OrganicCard(
                radius: AppTheme.radiusLg,
                child: Column(
                  children: [
                    _ReceiptRow(label: 'Order', value: '#GC-2048'),
                    SizedBox(height: 12),
                    _ReceiptRow(
                      label: 'Delivery',
                      value: 'Today, 5:00 - 7:00 PM',
                    ),
                    SizedBox(height: 12),
                    _ReceiptRow(label: 'Payment', value: 'Visa 4242'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 460),
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.go(OrderTrackingScreen.pathFor('GC-2048')),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Track Order'),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 540),
              child: OutlinedButton(
                onPressed: () => context.go(HomeScreen.routePath),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.charcoalInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
