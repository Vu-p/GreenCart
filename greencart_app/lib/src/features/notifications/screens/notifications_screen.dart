import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/deals/screens/deals_screen.dart';
import 'package:greencart_app/src/features/notifications/data/notification_repository.dart';
import 'package:greencart_app/src/features/notifications/models/app_notification.dart';
import 'package:greencart_app/src/features/orders/screens/order_tracking_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const routePath = '/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Notifications',
          subtitle: 'Updates on your orders and offers',
        ),
        actions: [
          IconButton(
            tooltip: 'Thử thông báo hệ thống',
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).triggerTestSystemNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi thông báo hệ thống xuống điện thoại!')),
                );
              }
            },
            icon: const Icon(Icons.send_to_mobile_outlined, color: AppTheme.primary),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải thông báo: $err')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: AppTheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.outline),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = list[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData _getIcon() {
    switch (notification.type) {
      case 'OrderStatus':
        return Icons.local_shipping_outlined;
      case 'Payment':
        return Icons.payment_outlined;
      case 'Promotion':
        return Icons.sell_outlined;
      case 'Substitution':
        return Icons.find_replace_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'OrderStatus':
        return AppTheme.primary;
      case 'Payment':
        return AppTheme.ripenedOrange;
      case 'Promotion':
        return AppTheme.coral;
      case 'Substitution':
        return Colors.blueAccent;
      default:
        return AppTheme.deepForest;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = notification.createdAt.toLocal();
    final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationCountProvider);
        }
        if (context.mounted) {
          if (notification.referenceId != null &&
              (notification.type == 'OrderStatus' ||
                  notification.type == 'Payment' ||
                  notification.type == 'Substitution')) {
            context.push(OrderTrackingScreen.pathFor(notification.referenceId!));
          } else if (notification.type == 'Promotion') {
            context.push(DealsScreen.routePath);
          }
        }
      },
      child: OrganicCard(
        color: notification.isRead ? AppTheme.surface : AppTheme.succulentGreen.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColor().withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), color: _getColor(), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: notification.isRead ? AppTheme.charcoalInk : AppTheme.deepForest,
                      ),
                ),
              ],
            ),
          ),
          if (!notification.isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.coral,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    ));
  }
}
