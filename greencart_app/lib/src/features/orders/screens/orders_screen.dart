import 'package:flutter/material.dart';

import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_action_icon.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/orders/data/mock_orders.dart';
import 'package:greencart_app/src/features/orders/widgets/active_order_card.dart';
import 'package:greencart_app/src/features/orders/widgets/order_tile.dart';
import 'package:greencart_app/src/features/orders/widgets/support_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const routePath = '/orders';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Order History',
          subtitle: 'Track weekly grocery runs',
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OrganicActionIcon(
              icon: Icons.receipt_long_outlined,
              onPressed: null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const ActiveOrderCard(),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recent Orders'),
          const SizedBox(height: 14),
          for (final order in mockOrders) ...[
            OrderTile(order: order),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
          const SupportCard(),
        ],
      ),
    );
  }
}
