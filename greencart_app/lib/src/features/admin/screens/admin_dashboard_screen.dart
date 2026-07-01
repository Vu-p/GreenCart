import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/organic_card.dart';
import '../../catalog/data/product_repository.dart';
import '../data/admin_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  static const routePath = '/admin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final productsAsync = ref.watch(adminProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.deepForest,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'GreenCart Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.deepForest, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 160,
                        color: Colors.white12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.storefront, color: Colors.white),
                onPressed: () => context.go('/'),
                tooltip: 'Marketplace',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operational Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoalInk,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Orders',
                          value: ordersAsync.when(
                            data: (orders) => orders.length.toString(),
                            loading: () => '...',
                            error: (_, __) => 'Err',
                          ),
                          icon: Icons.receipt_long,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Products',
                          value: productsAsync.when(
                            data: (products) => products.length.toString(),
                            loading: () => '...',
                            error: (_, __) => 'Err',
                          ),
                          icon: Icons.shopping_bag_outlined,
                          color: AppTheme.ripenedOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Categories',
                          value: categoriesAsync.when(
                            data: (categories) => categories.length.toString(),
                            loading: () => '...',
                            error: (_, __) => 'Err',
                          ),
                          icon: Icons.category_outlined,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Administrative Controls',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.charcoalInk,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 100),
                    child: _ControlCard(
                      title: 'Product Catalog',
                      subtitle: 'Add, update, and manage inventory items',
                      icon: Icons.grid_view_rounded,
                      color: AppTheme.primary,
                      onTap: () => context.push('/admin/products'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 180),
                    child: _ControlCard(
                      title: 'Categories',
                      subtitle: 'Organize catalog collections and taxonomy',
                      icon: Icons.category_rounded,
                      color: AppTheme.ripenedOrange,
                      onTap: () => context.push('/admin/categories'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 260),
                    child: _ControlCard(
                      title: 'Order Tracking & Status',
                      subtitle: 'Fulfill customer orders and propose replacements',
                      icon: Icons.local_shipping_rounded,
                      color: Colors.blueAccent,
                      onTap: () => context.push('/admin/orders'),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.storefront),
                      label: const Text('Return to Customer Marketplace'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(16),
      radius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.charcoalInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: EdgeInsets.zero,
      radius: AppTheme.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.charcoalInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.outline,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
