import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/checkout/screens/checkout_screen.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({
    required this.subtotal,
    required this.delivery,
    required this.total,
    super.key,
  });

  final double subtotal;
  final double delivery;
  final double total;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      radius: AppTheme.radiusLg,
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Delivery', value: delivery),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.mistGray),
          ),
          _SummaryRow(label: 'Total', value: total, emphasized: true),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push(CheckoutScreen.routePath),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Checkout Securely'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: emphasized
              ? Theme.of(context).textTheme.titleSmall
              : Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        Text(
          formatCurrency(value),
          style: TextStyle(
            color: emphasized ? AppTheme.primary : AppTheme.charcoalInk,
            fontSize: emphasized ? 22 : 16,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
