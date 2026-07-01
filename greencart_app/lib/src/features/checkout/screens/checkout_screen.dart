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
import 'package:greencart_app/src/features/checkout/application/checkout_draft_controller.dart';
import 'package:greencart_app/src/features/checkout/data/checkout_repository.dart';
import 'package:greencart_app/src/features/checkout/data/mock_checkout.dart';
import 'package:greencart_app/src/features/checkout/models/delivery_slot.dart';
import 'package:greencart_app/src/features/checkout/screens/substitution_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  static const routePath = '/checkout';

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _initializedFromPreview = false;

  Future<void> _editAddress() async {
    final draft = ref.read(checkoutDraftProvider);
    if (draft == null) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController(
      text: draft.deliveryAddress,
    );
    final phoneController = TextEditingController(text: draft.deliveryPhone);
    final phoneFocusNode = FocusNode();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Delivery Address',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => phoneFocusNode.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: 'Street address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 5) {
                        return 'Enter a complete delivery address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneController,
                    focusNode: phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    onFieldSubmitted: (_) {
                      if (formKey.currentState!.validate()) {
                        ref
                            .read(checkoutDraftProvider.notifier)
                            .updateAddress(
                              address: addressController.text,
                              phone: phoneController.text,
                            );
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      ref
                          .read(checkoutDraftProvider.notifier)
                          .updateAddress(
                            address: addressController.text,
                            phone: phoneController.text,
                          );
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Save Address'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    addressController.dispose();
    phoneController.dispose();
    phoneFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewState = ref.watch(checkoutPreviewProvider);
    final draft = ref.watch(checkoutDraftProvider);

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
                onPressed:
                    preview.items.isEmpty ||
                        draft == null ||
                        draft.deliveryAddress.trim().isEmpty ||
                        draft.deliverySlot == null
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
        data: (preview) {
          if (!_initializedFromPreview) {
            _initializedFromPreview = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(checkoutDraftProvider.notifier).initialize(preview);
              }
            });
          }

          final activeDraft = draft;
          return ListView(
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
                              activeDraft?.deliveryAddress ??
                                  preview.deliveryAddress ??
                                  '42 Green Valley Rd, Ho Chi Minh City, Vietnam',
                              style: const TextStyle(
                                color: AppTheme.outline,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeDraft?.deliveryPhone ??
                                  preview.deliveryPhone ??
                                  'No phone number',
                              style: const TextStyle(
                                color: AppTheme.outline,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: activeDraft == null ? null : _editAddress,
                        child: const Text('Edit'),
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
                  child: _DeliverySlotCard(
                    slot: slot,
                    selected: activeDraft?.deliverySlot == slot,
                    onTap: activeDraft == null
                        ? null
                        : () => ref
                              .read(checkoutDraftProvider.notifier)
                              .selectSlot(slot),
                  ),
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
                        value:
                            activeDraft?.deliverySlot?.price ??
                            preview.deliveryFee,
                      ),
                      const Divider(height: 26, color: AppTheme.mistGray),
                      _SummaryRow(
                        label: 'Total Amount',
                        value:
                            preview.subtotal +
                            (activeDraft?.deliverySlot?.price ??
                                preview.deliveryFee),
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (activeDraft?.deliverySlot == null) ...[
                const SizedBox(height: 2),
                const Text(
                  'Select a delivery slot to continue.',
                  style: TextStyle(
                    color: AppTheme.ripenedOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          );
        },
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
          icon: Icons.qr_code_2,
          label: 'PayOS QR / Bank Transfer',
          selected: true,
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
  const _DeliverySlotCard({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final DeliverySlot slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: OrganicCard(
        padding: const EdgeInsets.all(14),
        color: selected ? AppTheme.succulentGreen : Colors.white,
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.primary : AppTheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          slot.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (slot.recommended) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppTheme.ripenedOrange,
                        ),
                      ],
                    ],
                  ),
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
