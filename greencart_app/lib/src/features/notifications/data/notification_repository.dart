import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/services/api_client.dart';
import 'package:greencart_app/src/core/services/local_notification_service.dart';
import 'package:greencart_app/src/features/notifications/models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    ref.watch(apiClientProvider),
    ref.watch(localNotificationServiceProvider),
  );
});

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final list = await ref.watch(notificationsProvider.future);
  return list.where((n) => !n.isRead).length;
});

class NotificationRepository {
  NotificationRepository(this._apiClient, this._localNotificationService);

  final ApiClient _apiClient;
  final LocalNotificationService _localNotificationService;
  static final Set<String> _notifiedIds = {};

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _apiClient.get('/api/notifications', authorized: true);
      final list = response.data as List<dynamic>;
      final notifications = list
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();

      // Kiểm tra thông báo chưa đọc mới để hiển thị Push Notification hệ thống trên điện thoại
      for (final n in notifications) {
        if (!n.isRead && !_notifiedIds.contains(n.id)) {
          _notifiedIds.add(n.id);
          // Trigger local push notification cho thông báo mới
          await _localNotificationService.showNotification(
            id: n.id.hashCode,
            title: n.title,
            body: n.message,
            payload: n.referenceId,
          );
        }
      }

      return notifications;
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.put('/api/notifications/$id/read', authorized: true);
  }

  Future<void> markAllAsRead() async {
    await _apiClient.put('/api/notifications/read-all', authorized: true);
  }

  Future<void> triggerTestSystemNotification() async {
    await _localNotificationService.showNotification(
      id: 9999,
      title: '🌿 GreenCart Thông Báo Hệ Thống',
      body: 'Đây là thông báo push hệ thống trên điện thoại của bạn! Đơn hàng #GC8892 đang trên đường giao tới bạn.',
    );
  }
}
