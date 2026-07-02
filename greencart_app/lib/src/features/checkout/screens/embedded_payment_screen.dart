import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/features/orders/screens/order_tracking_screen.dart';
import 'package:greencart_app/src/features/checkout/screens/payment_cancelled_screen.dart';

class EmbeddedPaymentScreen extends StatefulWidget {
  const EmbeddedPaymentScreen({
    required this.checkoutUrl,
    required this.orderId,
    required this.orderNumber,
    this.qrCode = '',
    super.key,
  });

  final String checkoutUrl;
  final String orderId;
  final String orderNumber;
  final String qrCode;

  static String pathFor(
    String orderId, {
    required String checkoutUrl,
    required String orderNumber,
    String qrCode = '',
  }) =>
      '/checkout/embedded?orderId=$orderId&orderNumber=$orderNumber&checkoutUrl=${Uri.encodeComponent(checkoutUrl)}&qrCode=${Uri.encodeComponent(qrCode)}';

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

  void _showQrDownloadModal() {
    HapticFeedback.mediumImpact();
    final qrData = widget.qrCode.isNotEmpty ? widget.qrCode : widget.checkoutUrl;
    final qrImageUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=20&data=${Uri.encodeComponent(qrData)}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mã QR Chuyển Khoản PayOS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tải ảnh QR về máy hoặc sao chép mã thanh toán để mở ứng dụng Ngân hàng (VietQR).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.outline),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.succulentGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    qrImageUrl,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final uri = Uri.parse(qrImageUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text(
                    '📥 Tải ảnh QR về máy (Mở trình duyệt)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: qrData));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Đã sao chép chuỗi mã QR vào khay nhớ tạm!'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.charcoalInk,
                    side: const BorderSide(color: AppTheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text(
                    'Sao chép chuỗi mã QR',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            tooltip: 'Tải & Xem QR',
            icon: const Icon(Icons.qr_code_2, color: AppTheme.primary),
            onPressed: _showQrDownloadModal,
          ),
          IconButton(
            tooltip: 'Tải lại',
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _showQrDownloadModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.qr_code_2, size: 22),
            label: const Text(
              '📥 Xem & Tải ảnh mã QR chuyển khoản',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
