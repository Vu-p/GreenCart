import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/features/orders/screens/order_tracking_screen.dart';
import 'package:greencart_app/src/features/checkout/screens/payment_cancelled_screen.dart';

class EmbeddedPaymentScreen extends StatefulWidget {
  const EmbeddedPaymentScreen({
    required this.checkoutUrl,
    required this.orderId,
    required this.orderNumber,
    super.key,
  });

  final String checkoutUrl;
  final String orderId;
  final String orderNumber;

  static String pathFor(String orderId, {required String checkoutUrl, required String orderNumber}) =>
      '/checkout/embedded?orderId=$orderId&orderNumber=$orderNumber&checkoutUrl=${Uri.encodeComponent(checkoutUrl)}';

  @override
  State<EmbeddedPaymentScreen> createState() => _EmbeddedPaymentScreenState();
}

class _EmbeddedPaymentScreenState extends State<EmbeddedPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            if (url.contains('/return') || url.contains('status=paid') || url.contains('code=00')) {
              if (mounted) {
                context.go(OrderTrackingScreen.pathFor(widget.orderId));
              }
              return NavigationDecision.prevent;
            }
            if (url.contains('/cancel') || url.contains('status=cancelled')) {
              if (mounted) {
                context.pushReplacement(
                  PaymentCancelledScreen.pathFor(widget.orderId, widget.orderNumber),
                );
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handleClose() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạm dừng thanh toán?'),
        content: const Text(
          'Đơn hàng của bạn đã được lưu lại. Bạn có muốn thoát màn hình thanh toán không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ở lại thanh toán'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ripenedOrange),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushReplacement(
                PaymentCancelledScreen.pathFor(widget.orderId, widget.orderNumber),
              );
            },
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thanh toán PayOS (${widget.orderNumber})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleClose,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
        ],
      ),
    );
  }
}
