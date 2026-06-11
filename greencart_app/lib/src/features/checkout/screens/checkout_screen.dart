import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/checkout/data/checkout_repository.dart';
import 'package:greencart_app/src/features/checkout/data/mock_checkout.dart';
import 'package:greencart_app/src/features/checkout/models/delivery_slot.dart';
import 'package:greencart_app/src/features/checkout/screens/substitution_screen.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  static const routePath = '/checkout';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(checkoutPreviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Checkout',
          subtitle: 'Confirm delivery and payment',
        ),
      ),
      body: previewState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 28),
          children: [
            OrganicStateMessage(
              icon: Icons.shopping_cart_checkout,
              title: 'Could not prepare checkout.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(checkoutPreviewProvider),
            ),
          ],
        ),
        data: (preview) => ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const AnimatedEntrance(
              child: SectionHeader(title: 'Delivery Address'),
            ),
            const SizedBox(height: 12),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 80),
              child: OrganicCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        preview.deliveryAddress ??
                            '221B Green Market Street\nDistrict 1, Ho Chi Minh City',
                        style: const TextStyle(
                          color: AppTheme.charcoalInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Delivery Slot'),
            const SizedBox(height: 12),
            for (final slot in deliverySlots) ...[
              AnimatedEntrance(
                delay: Duration(
                  milliseconds: 120 + (deliverySlots.indexOf(slot) * 80),
                ),
                child: _DeliverySlotCard(slot: slot),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            const SectionHeader(title: 'Payment'),
            const SizedBox(height: 12),
            const AnimatedEntrance(
              delay: Duration(milliseconds: 420),
              child: OrganicCard(
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
            ),
            const SizedBox(height: 22),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 520),
              child: OrganicCard(
                radius: AppTheme.radiusLg,
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: preview.subtotal),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Delivery', value: preview.deliveryFee),
                    const Divider(height: 28, color: AppTheme.mistGray),
                    _SummaryRow(
                      label: 'Total',
                      value: preview.total,
                      emphasized: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: preview.items.isEmpty
                          ? null
                          : () => context.push(SubstitutionScreen.routePath),
                      icon: const Icon(Icons.sync_alt),
                      label: const Text('Review Substitutions'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
