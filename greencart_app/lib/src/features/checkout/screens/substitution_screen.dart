import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/checkout/application/checkout_draft_controller.dart';
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
      final draft = ref.read(checkoutDraftProvider);
      if (draft == null || draft.deliverySlot == null) {
        throw StateError('Checkout delivery details are incomplete.');
      }
      final order = await ref
          .read(checkoutRepositoryProvider)
          .checkout(
            deliveryAddress: draft.deliveryAddress,
            deliveryPhone: draft.deliveryPhone,
            deliverySlot: draft.deliverySlot!.value,
            substitutionPreference: substitutionOptions[_selectedIndex],
          );
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider);
      ref.read(checkoutDraftProvider.notifier).clear();
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
          title: 'GreenCart',
          subtitle: 'Substitution Options',
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'OUT OF STOCK',
            style: TextStyle(
              color: AppTheme.outline,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find a substitution for Organic Whole Milk',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your original choice is currently unavailable. We found similar products and sorted them by lower price first.',
            style: TextStyle(
              color: AppTheme.outline,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          const _OriginalProductCard(),
          const SizedBox(height: 22),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'SMART SUBSTITUTIONS',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '2 options available',
                style: TextStyle(color: AppTheme.outline, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < 2; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () => setState(() => _selectedIndex = i),
              child: _SubstitutionOptionCard(
                selected: i == _selectedIndex,
                index: i,
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _isPaying ? null : _pay,
            icon: const Icon(Icons.check_circle_outline),
            label: _isPaying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Accept Substitution'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isPaying ? null : _pay,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove from Cart'),
          ),
        ],
      ),
    );
  }
}

class _OriginalProductCard extends StatelessWidget {
  const _OriginalProductCard();

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(12),
      color: AppTheme.surfaceContainerLow,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&q=80&w=500',
              width: 66,
              height: 66,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original Selection',
                  style: TextStyle(
                    color: AppTheme.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Organic Whole Milk',
                  style: TextStyle(
                    color: AppTheme.charcoalInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '1 Gallon - \$5.48',
                  style: TextStyle(color: AppTheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubstitutionOptionCard extends StatelessWidget {
  const _SubstitutionOptionCard({required this.selected, required this.index});

  final bool selected;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    return OrganicCard(
      padding: const EdgeInsets.all(12),
      color: selected ? AppTheme.succulentGreen : Colors.white,
      radius: AppTheme.radiusMd,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              isFirst
                  ? 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=500'
                  : 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&q=80&w=500',
              width: 72,
              height: 86,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirst)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'BEST MATCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (isFirst) const SizedBox(height: 7),
                Text(
                  isFirst ? 'Non-GMO Whole Milk' : 'Organic 2% Milk',
                  style: const TextStyle(
                    color: AppTheme.charcoalInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      isFirst ? '\$5.25' : '\$5.49',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFirst ? 'Save \$0.23' : 'Similar',
                      style: const TextStyle(
                        color: AppTheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  '1 Gallon',
                  style: TextStyle(color: AppTheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_off,
            color: selected ? AppTheme.primary : AppTheme.outline,
          ),
        ],
      ),
    );
  }
}
