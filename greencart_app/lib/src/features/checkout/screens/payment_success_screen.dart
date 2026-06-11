import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
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
            Container(
              width: 104,
              height: 104,
              margin: const EdgeInsets.symmetric(horizontal: 90),
              decoration: BoxDecoration(
                color: AppTheme.succulentGreen,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.primary,
                size: 58,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Confirmed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.charcoalInk,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your GreenCart order is being packed for delivery today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.outline,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            const OrganicCard(
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.go(OrderTrackingScreen.pathFor('GC-2048')),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Track Order'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(HomeScreen.routePath),
              child: const Text('Back to Home'),
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
