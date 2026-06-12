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
    this.enabled = true,
    super.key,
  });

  final double subtotal;
  final double delivery;
  final double total;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      radius: AppTheme.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Shipping Fee',
            value: delivery,
            freeWhenZero: true,
          ),
          const Divider(height: 28, color: AppTheme.mistGray),
          _SummaryRow(label: 'Total', value: total, emphasized: true),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: enabled
                ? () => context.push(CheckoutScreen.routePath)
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Proceed to Checkout'),
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
    this.freeWhenZero = false,
  });

  final String label;
  final double value;
  final bool emphasized;
  final bool freeWhenZero;

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
          freeWhenZero && value == 0 ? 'FREE' : formatCurrency(value),
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
