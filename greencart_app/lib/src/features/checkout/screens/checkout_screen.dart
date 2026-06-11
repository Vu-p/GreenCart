import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/cart/data/mock_cart_items.dart';
import 'package:greencart_app/src/features/checkout/data/mock_checkout.dart';
import 'package:greencart_app/src/features/checkout/models/delivery_slot.dart';
import 'package:greencart_app/src/features/checkout/screens/substitution_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  static const routePath = '/checkout';

  @override
  Widget build(BuildContext context) {
    final subtotal = mockCartItems.fold<double>(
      0,
      (total, item) => total + item.price * item.quantity,
    );
    final delivery = deliverySlots.first.price;
    final total = subtotal + delivery;

    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Checkout',
          subtitle: 'Confirm delivery and payment',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const SectionHeader(title: 'Delivery Address'),
          const SizedBox(height: 12),
          const OrganicCard(
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppTheme.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '221B Green Market Street\nDistrict 1, Ho Chi Minh City',
                    style: TextStyle(
                      color: AppTheme.charcoalInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Delivery Slot'),
          const SizedBox(height: 12),
          for (final slot in deliverySlots) ...[
            _DeliverySlotCard(slot: slot),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          const SectionHeader(title: 'Payment'),
          const SizedBox(height: 12),
          const OrganicCard(
            child: Row(
              children: [
                Icon(Icons.credit_card, color: AppTheme.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Visa ending in 4242',
                    style: TextStyle(
                      color: AppTheme.charcoalInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.check_circle, color: AppTheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OrganicCard(
            radius: AppTheme.radiusLg,
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: subtotal),
                const SizedBox(height: 10),
                _SummaryRow(label: 'Delivery', value: delivery),
                const Divider(height: 28, color: AppTheme.mistGray),
                _SummaryRow(label: 'Total', value: total, emphasized: true),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.go(SubstitutionScreen.routePath),
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Review Substitutions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverySlotCard extends StatelessWidget {
  const _DeliverySlotCard({required this.slot});

  final DeliverySlot slot;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      color: slot.recommended ? AppTheme.succulentGreen : Colors.white,
      child: Row(
        children: [
          Icon(
            slot.recommended ? Icons.star_rounded : Icons.schedule,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  slot.window,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            slot.price == 0 ? 'Free' : formatCurrency(slot.price),
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
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
