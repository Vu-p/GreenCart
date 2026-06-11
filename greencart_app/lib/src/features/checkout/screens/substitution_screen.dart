import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/checkout/data/checkout_repository.dart';
import 'package:greencart_app/src/features/checkout/data/mock_checkout.dart';
import 'package:greencart_app/src/features/checkout/screens/payment_success_screen.dart';
import 'package:greencart_app/src/features/orders/data/orders_repository.dart';

class SubstitutionScreen extends ConsumerStatefulWidget {
  const SubstitutionScreen({super.key});

  static const routePath = '/checkout/substitution';

  @override
  ConsumerState<SubstitutionScreen> createState() => _SubstitutionScreenState();
}

class _SubstitutionScreenState extends ConsumerState<SubstitutionScreen> {
  int _selectedIndex = 0;
  bool _isPaying = false;

  Future<void> _pay() async {
    setState(() => _isPaying = true);
    try {
      final preview = await ref.read(checkoutRepositoryProvider).preview();
      final order = await ref
          .read(checkoutRepositoryProvider)
          .checkout(
            deliveryAddress:
                preview.deliveryAddress ??
                '221B Green Market Street, District 1, Ho Chi Minh City',
            deliveryPhone: preview.deliveryPhone,
            substitutionPreference: substitutionOptions[_selectedIndex],
          );
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider);
      if (mounted) {
        context.go(
          PaymentSuccessScreen.pathFor(
            orderId: order.id,
            orderNumber: order.orderNumber,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment could not be completed. Check your cart.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Substitutions',
          subtitle: 'Choose what happens if items run out',
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const OrganicPromoBanner(
            eyebrow: 'SMART SWAPS',
            title: 'TH Fresh Milk may be unavailable today.',
            subtitle: 'Pick a preference before final payment.',
            icon: Icons.compare_arrows,
            color: AppTheme.deepForest,
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < substitutionOptions.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () => setState(() => _selectedIndex = i),
              child: OrganicCard(
                color: i == _selectedIndex
                    ? AppTheme.succulentGreen
                    : Colors.white,
                child: Row(
                  children: [
                    Icon(
                      i == _selectedIndex
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        substitutionOptions[i],
                        style: const TextStyle(
                          color: AppTheme.charcoalInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _isPaying ? null : _pay,
            icon: const Icon(Icons.lock_outline),
            label: _isPaying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Pay Securely'),
          ),
        ],
      ),
    );
  }
}
