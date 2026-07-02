import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/orders/data/orders_repository.dart';
import 'package:greencart_app/src/features/orders/screens/orders_screen.dart';
import 'package:greencart_app/src/features/checkout/screens/embedded_payment_screen.dart';

class PaymentCancelledScreen extends ConsumerStatefulWidget {
  const PaymentCancelledScreen({
    required this.orderId,
    required this.orderNumber,
    super.key,
  });

  final String orderId;
  final String orderNumber;

  static String pathFor(String orderId, String orderNumber) =>
      '/checkout/cancelled?orderId=$orderId&orderNumber=$orderNumber';

  @override
  ConsumerState<PaymentCancelledScreen> createState() =>
      _PaymentCancelledScreenState();
}

class _PaymentCancelledScreenState
    extends ConsumerState<PaymentCancelledScreen> {
  bool _isRetrying = false;
  bool _isCancelling = false;

  Future<void> _handleRetryPayment() async {
    setState(() => _isRetrying = true);
    try {
      final payment = await ref
          .read(ordersRepositoryProvider)
          .repayOrder(widget.orderId);
      if (mounted) {
        context.pushReplacement(
          EmbeddedPaymentScreen.pathFor(
            payment.order.id,
            checkoutUrl: payment.checkoutUrl,
            orderNumber: widget.orderNumber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lấy link thanh toán mới: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  Future<void> _handleCancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đơn?'),
        content: Text(
          'Bạn chắc chắn muốn hủy đơn hàng ${widget.orderNumber}? Sản phẩm sẽ được hoàn lại vào kho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.ripenedOrange,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đồng ý hủy'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(widget.orderId);
      ref.invalidate(ordersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hủy đơn hàng ${widget.orderNumber} thành công.'),
          ),
        );
        context.go(OrdersScreen.routePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi hủy đơn hàng: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán chưa hoàn tất'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.ripenedOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment_outlined,
                  color: AppTheme.ripenedOrange,
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Đơn hàng ${widget.orderNumber}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoalInk,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thanh toán PayOS cho đơn hàng này đã bị tạm dừng hoặc chưa hoàn tất. Bạn muốn thực hiện tiếp thanh toán hay hủy đơn hàng?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.outline,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              OrganicCard(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isRetrying || _isCancelling)
                                ? null
                                : _handleRetryPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        icon:
                            _isRetrying
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Thanh toán lại ngay',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed:
                            (_isRetrying || _isCancelling)
                                ? null
                                : _handleCancelOrder,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.ripenedOrange),
                          foregroundColor: AppTheme.ripenedOrange,
                        ),
                        icon:
                            _isCancelling
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.ripenedOrange,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.cancel_outlined),
                        label: const Text(
                          'Hủy đơn hàng này',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(OrdersScreen.routePath),
                child: const Text('Xem danh sách đơn hàng của tôi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
