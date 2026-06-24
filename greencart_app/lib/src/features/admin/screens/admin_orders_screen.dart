import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/organic_card.dart';
import '../../../core/widgets/organic_state_message.dart';
import '../../catalog/models/product.dart';
import '../../orders/models/order_item.dart';
import '../data/admin_repository.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  static const routePath = '/admin/orders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.charcoalInk,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminOrdersProvider),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OrganicStateMessage(
                icon: Icons.receipt_long_outlined,
                title: 'Could not load admin orders',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(adminOrdersProvider),
              ),
            ],
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  OrganicStateMessage(
                    icon: Icons.receipt_long_outlined,
                    title: 'No customer orders found',
                    actionLabel: 'Refresh',
                    onAction: () => ref.invalidate(adminOrdersProvider),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AnimatedEntrance(
                    delay: Duration(milliseconds: index * 50),
                    child: _AdminOrderCard(order: order),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerStatefulWidget {
  const _AdminOrderCard({required this.order});

  final OrderItem order;

  @override
  ConsumerState<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends ConsumerState<_AdminOrderCard> {
  bool _isExpanded = false;
  bool _isUpdatingStatus = false;

  Color _getStatusColor(String status) {
    return switch (status) {
      'Pending' => Colors.orange,
      'Confirmed' => Colors.blue,
      'Packing' => Colors.purple,
      'Delivering' => Colors.teal,
      'Completed' => AppTheme.primary,
      'Cancelled' => Colors.red,
      _ => AppTheme.outline,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'Pending' => Icons.hourglass_empty,
      'Confirmed' => Icons.check_circle_outline,
      'Packing' => Icons.inventory_2_outlined,
      'Delivering' => Icons.local_shipping_outlined,
      'Completed' => Icons.task_alt,
      'Cancelled' => Icons.cancel_outlined,
      _ => Icons.help_outline,
    };
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateOrderStatus(widget.order.id, newStatus);
      ref.invalidate(adminOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final statuses = [
          'Pending',
          'Confirmed',
          'Packing',
          'Delivering',
          'Completed',
          'Cancelled',
        ];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Update Order Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.charcoalInk,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...statuses.map((status) {
                final isSelected = widget.order.status == status;
                return ListTile(
                  leading: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                  title: Text(
                    status,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : AppTheme.charcoalInk,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isSelected) {
                      _updateStatus(status);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _proposeSubstitution(OrderLineItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProposeSubstitutionDialog(
        orderId: widget.order.id,
        lineItem: item,
      ),
    ).then((success) {
      if (success == true) {
        ref.invalidate(adminOrdersProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt);

    return OrganicCard(
      padding: EdgeInsets.zero,
      radius: AppTheme.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.charcoalInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.outline,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible/Expandable Content
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppTheme.mistGray),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer details
                  const Text(
                    'Delivery Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.charcoalInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order.deliveryPhone != null &&
                      order.deliveryPhone!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 16, color: AppTheme.outline),
                        const SizedBox(width: 8),
                        Text(
                          order.deliveryPhone!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.charcoalInk,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (order.substitutionPreference != null &&
                      order.substitutionPreference!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.swap_horiz_outlined,
                            size: 16, color: AppTheme.outline),
                        const SizedBox(width: 8),
                        Text(
                          'Preference: ${order.substitutionPreference}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.charcoalInk,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Divider(height: 24, color: AppTheme.mistGray),

                  // Order items list
                  const Text(
                    'Items & Substitutions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final item = order.items[idx];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl.isNotEmpty
                                  ? item.imageUrl
                                  : 'https://images.unsplash.com/photo-1542838132-92c53300491e',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: AppTheme.mistGray,
                                child: const Icon(Icons.shopping_bag_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.charcoalInk,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item.quantity} x ${formatCurrency(item.unitPrice)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency(item.lineTotal),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.charcoalInk,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (order.status != 'Completed' &&
                                  order.status != 'Cancelled')
                                InkWell(
                                  onTap: () => _proposeSubstitution(item),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppTheme.primary, width: 1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Replace',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const Divider(height: 24, color: AppTheme.mistGray),

                  // Pricing total
                  Row(
                    children: [
                      const Text('Subtotal',
                          style: TextStyle(color: AppTheme.outline, fontSize: 13)),
                      const Spacer(),
                      Text(formatCurrency(order.subtotal),
                          style: const TextStyle(
                              color: AppTheme.charcoalInk, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Delivery Fee',
                          style: TextStyle(color: AppTheme.outline, fontSize: 13)),
                      const Spacer(),
                      Text(formatCurrency(order.deliveryFee),
                          style: const TextStyle(
                              color: AppTheme.charcoalInk, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.charcoalInk,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatCurrency(order.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdatingStatus ? null : _showStatusPicker,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      icon: _isUpdatingStatus
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(statusIcon, size: 18),
                      label: Text(
                        _isUpdatingStatus
                            ? 'Updating Status...'
                            : 'Update Order Status',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProposeSubstitutionDialog extends ConsumerStatefulWidget {
  const _ProposeSubstitutionDialog({
    required this.orderId,
    required this.lineItem,
  });

  final String orderId;
  final OrderLineItem lineItem;

  @override
  ConsumerState<_ProposeSubstitutionDialog> createState() =>
      _ProposeSubstitutionDialogState();
}

class _ProposeSubstitutionDialogState
    extends ConsumerState<_ProposeSubstitutionDialog> {
  final _noteController = TextEditingController();
  String? _selectedProductId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a replacement product.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(adminRepositoryProvider).proposeSubstitution(
            orderId: widget.orderId,
            orderItemId: widget.lineItem.id,
            originalProductId: widget.lineItem.productId ?? '',
            replacementProductId: _selectedProductId!,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Substitution proposal sent.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to propose substitution: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);

    return AlertDialog(
      title: const Text('Propose Replacement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original item: ${widget.lineItem.productName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Replacement Product:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline),
            ),
            const SizedBox(height: 8),
            productsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(
                'Error loading products: $err',
                style: const TextStyle(color: Colors.red),
              ),
              data: (products) {
                // Filter out the original product to avoid recommending it as a replacement
                final otherProducts = products
                    .where((p) => p.id != widget.lineItem.productId)
                    .toList();

                if (otherProducts.isEmpty) {
                  return const Text('No other products available.');
                }

                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedProductId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Choose product'),
                  items: otherProducts.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              p.imageUrl,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${p.name} (${formatCurrency(p.price)})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProductId = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Add note for customer (optional):',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'e.g. Out of stock, recommending larger organic option',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send Proposal'),
        ),
      ],
    );
  }
}
