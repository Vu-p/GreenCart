import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'package:greencart_app/src/core/services/local_notification_service.dart';
import 'package:greencart_app/src/features/auth/data/auth_repository.dart';
import 'package:greencart_app/src/features/notifications/data/notification_repository.dart';

final signalRServiceProvider = Provider<SignalRService>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final localNotif = ref.watch(localNotificationServiceProvider);
  return SignalRService(authRepo, localNotif, ref);
});

class SignalRService {
  SignalRService(this._authRepository, this._localNotificationService, this._ref);

  final AuthRepository _authRepository;
  final LocalNotificationService _localNotificationService;
  final Ref _ref;
  HubConnection? _hubConnection;

  Future<void> connect(String userId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      return;
    }

    final token = await _authRepository.getAccessToken();
    if (token == null) return;

    // Thay đổi URL theo địa chỉ máy chủ thật hoặc máy ảo (10.0.2.2 cho Android Emulator)
    const hubUrl = 'http://10.0.2.2:5000/hubs/orders';

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on('ReceiveNotification', _onReceiveNotification);
    _hubConnection?.on('OrderStatusChanged', _onOrderStatusChanged);
    _hubConnection?.on('SubstitutionProposed', _onSubstitutionProposed);

    try {
      await _hubConnection?.start();
      await _hubConnection?.invoke('JoinUser', args: [userId]);
    } catch (_) {
      // Xử lý lỗi kết nối ngầm khi máy chủ ngoại tuyến
    }
  }

  void _invalidateNotificationProviders() {
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  void _onReceiveNotification(List<Object?>? arguments) {
    _invalidateNotificationProviders();
    if (arguments == null || arguments.isEmpty) return;
    final payload = arguments.first as Map<String, dynamic>?;
    if (payload == null) return;

    final title = payload['title']?.toString() ?? 'Thông báo mới';
    final message = payload['message']?.toString() ?? 'Bạn có một thông báo từ GreenCart';
    final refId = payload['referenceId']?.toString();

    _localNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: message,
      payload: refId,
    );
  }

  void _onOrderStatusChanged(List<Object?>? arguments) {
    _invalidateNotificationProviders();
    _localNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '📦 Cập nhật đơn hàng',
      body: 'Trạng thái đơn hàng của bạn vừa có sự thay đổi.',
    );
  }

  void _onSubstitutionProposed(List<Object?>? arguments) {
    _invalidateNotificationProviders();
    _localNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '🔄 Đề xuất thay thế sản phẩm',
      body: 'Cửa hàng vừa gửi đề xuất thay thế cho sản phẩm đã hết hàng trong đơn của bạn.',
    );
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }
}
