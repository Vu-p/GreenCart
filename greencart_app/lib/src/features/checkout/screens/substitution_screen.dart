import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/features/checkout/data/mock_checkout.dart';
import 'package:greencart_app/src/features/checkout/screens/payment_success_screen.dart';

class SubstitutionScreen extends StatelessWidget {
  const SubstitutionScreen({super.key});

  static const routePath = '/checkout/substitution';

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
            OrganicCard(
              color: i == 0 ? AppTheme.succulentGreen : Colors.white,
              child: Row(
                children: [
                  Icon(
                    i == 0
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
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => context.push(PaymentSuccessScreen.routePath),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Pay Securely'),
          ),
        ],
      ),
    );
  }
}
