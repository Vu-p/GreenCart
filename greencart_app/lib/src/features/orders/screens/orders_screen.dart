import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_action_icon.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/orders/data/orders_repository.dart';
import 'package:greencart_app/src/features/orders/widgets/active_order_card.dart';
import 'package:greencart_app/src/features/orders/widgets/order_tile.dart';
import 'package:greencart_app/src/features/orders/widgets/support_card.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const routePath = '/orders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersProvider);

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
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersProvider),
        child: ordersState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 28),
            children: [
              OrganicStateMessage(
                icon: Icons.receipt_long_outlined,
                title: 'Could not load orders.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(ordersProvider),
              ),
            ],
          ),
          data: (orders) {
            final activeOrders = orders.where((o) => o.active).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (activeOrders.isNotEmpty) ...[
                  ActiveOrderCard(orders: activeOrders),
                  const SizedBox(height: 24),
                ],
                const SectionHeader(title: 'Recent Orders'),
              const SizedBox(height: 14),
              if (orders.isEmpty)
                OrganicStateMessage(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet.',
                  actionLabel: 'Refresh',
                  onAction: () => ref.invalidate(ordersProvider),
                )
              else
                for (final order in orders) ...[
                  OrderTile(order: order),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 10),
              const SupportCard(),
            ],
          );
        },
      ),
      ),
    );
  }
}
