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
      bottomNavigationBar: previewState.maybeWhen(
        data: (preview) => SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: preview.items.isEmpty
                    ? null
                    : () => context.push(SubstitutionScreen.routePath),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Place Order'),
              ),
              const SizedBox(height: 8),
              const Text(
                'By tapping Place Order you agree to our Terms of Service.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.outline, fontSize: 11),
              ),
            ],
          ),
        ),
        orElse: () => null,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
          children: [
            const _CheckoutStepper(currentStep: 0),
            const SizedBox(height: 22),
            const AnimatedEntrance(
              child: SectionHeader(title: 'Shipping Address'),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Home',
                            style: TextStyle(
                              color: AppTheme.charcoalInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preview.deliveryAddress ??
                                '42 Green Valley Rd\nHo Chi Minh City, Vietnam',
                            style: const TextStyle(
                              color: AppTheme.outline,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preview.deliveryPhone ?? '+1 (555) 000-1234',
                            style: const TextStyle(
                              color: AppTheme.outline,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Edit')),
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
            const SectionHeader(title: 'Payment Method'),
            const SizedBox(height: 12),
            const AnimatedEntrance(
              delay: Duration(milliseconds: 420),
              child: _PaymentMethods(),
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
                    _SummaryRow(
                      label: 'Delivery Fee',
                      value: preview.deliveryFee,
                    ),
                    const Divider(height: 26, color: AppTheme.mistGray),
                    _SummaryRow(
                      label: 'Total Amount',
                      value: preview.total,
                      emphasized: true,
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

class _CheckoutStepper extends StatelessWidget {
  const _CheckoutStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Shipping', 'Delivery', 'Payment'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: i <= currentStep
                      ? AppTheme.primary
                      : AppTheme.surfaceContainer,
                  child: i < currentStep
                      ? const Icon(Icons.check, color: Colors.white, size: 15)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: i <= currentStep
                                ? Colors.white
                                : AppTheme.outline,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  style: TextStyle(
                    color: i <= currentStep
                        ? AppTheme.primary
                        : AppTheme.outline,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (i != labels.length - 1)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.only(bottom: 24),
                color: AppTheme.mistGray,
              ),
            ),
        ],
      ],
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _PaymentMethodRow(
          icon: Icons.credit_card,
          label: 'Credit / Debit Card',
          selected: true,
        ),
        SizedBox(height: 10),
        _PaymentMethodRow(icon: Icons.apple, label: 'Apple Pay'),
        SizedBox(height: 10),
        _PaymentMethodRow(
          icon: Icons.payments_outlined,
          label: 'COD (Cash on Delivery)',
        ),
      ],
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      color: Colors.white,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppTheme.primary : AppTheme.outline,
            size: 20,
          ),
          const SizedBox(width: 10),
          Icon(icon, color: AppTheme.charcoalInk, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.charcoalInk,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
