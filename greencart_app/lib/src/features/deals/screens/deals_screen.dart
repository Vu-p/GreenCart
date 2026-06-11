import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/cart/screens/cart_screen.dart';
import 'package:greencart_app/src/features/deals/data/mock_deals.dart';
import 'package:greencart_app/src/features/deals/models/deal_bundle.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  static const routePath = '/deals';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Fresh Deals',
          subtitle: 'Seasonal bundles and smart savings',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const OrganicPromoBanner(
            eyebrow: 'TODAY ONLY',
            title: 'Save more on organic weekly essentials.',
            subtitle: 'Curated baskets for healthy routines.',
            icon: Icons.sell_outlined,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Bundles'),
          const SizedBox(height: 14),
          for (final deal in dealBundles) ...[
            _DealBundleCard(deal: deal),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const SectionHeader(title: 'Coupons'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final code in couponCodes)
                Chip(
                  avatar: const Icon(Icons.confirmation_number_outlined),
                  label: Text(code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DealBundleCard extends StatelessWidget {
  const _DealBundleCard({required this.deal});

  final DealBundle deal;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: deal.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(deal.icon, color: AppTheme.primary, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal.badge, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(deal.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  deal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formatCurrency(deal.price),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrency(deal.originalPrice),
                      style: const TextStyle(
                        color: AppTheme.outline,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () => context.go(CartScreen.routePath),
            style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
