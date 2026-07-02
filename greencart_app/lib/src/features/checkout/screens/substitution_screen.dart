import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/features/checkout/screens/embedded_payment_screen.dart';
import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/utils/currency_formatter.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/cart/data/cart_repository.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';
import 'package:greencart_app/src/features/catalog/models/product.dart';
import 'package:greencart_app/src/features/checkout/application/checkout_draft_controller.dart';
import 'package:greencart_app/src/features/checkout/data/checkout_repository.dart';
import 'package:greencart_app/src/features/orders/data/orders_repository.dart';

class SubstitutionScreen extends ConsumerStatefulWidget {
  const SubstitutionScreen({super.key});

  static const routePath = '/checkout/substitution';

  @override
  ConsumerState<SubstitutionScreen> createState() => _SubstitutionScreenState();
}

class _SubstitutionScreenState extends ConsumerState<SubstitutionScreen> {
  static const substitutionOptions = [
    'Cho phép AI đề xuất món thay thế tốt nhất',
    'Hoàn tiền lập tức nếu hết hàng',
    'Liên hệ qua điện thoại trước khi giao',
  ];

  int _selectedIndex = 0;
  bool _isPaying = false;

  Future<void> _pay() async {
    setState(() => _isPaying = true);
    try {
      final draft = ref.read(checkoutDraftProvider);
      if (draft == null || draft.deliverySlot == null) {
        throw StateError('Checkout delivery details are incomplete.');
      }
      final payment = await ref
          .read(checkoutRepositoryProvider)
          .checkout(
            deliveryAddress: draft.deliveryAddress,
            deliveryPhone: draft.deliveryPhone,
            deliverySlot: draft.deliverySlot!.value,
            substitutionPreference: substitutionOptions[_selectedIndex],
          );
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider);
      ref.read(checkoutDraftProvider.notifier).clear();
      if (mounted) {
        context.push(
          EmbeddedPaymentScreen.pathFor(
            payment.order.id,
            checkoutUrl: payment.checkoutUrl,
            orderNumber: payment.order.orderNumber,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not create the PayOS checkout. Check your cart.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'GreenCart',
          subtitle: 'Tùy chọn thay thế sản phẩm',
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.succulentGreen,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chính sách thay thế linh hoạt',
                        style: TextStyle(
                          color: AppTheme.charcoalInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chỉ khi sản phẩm bạn chọn hết hàng lúc đóng gói hoặc có lựa chọn tương tự giá rẻ hơn, hệ thống mới đề xuất thay thế. Bạn hoàn toàn có thể từ chối thay thế và nhận hoàn tiền ngay.',
                        style: TextStyle(
                          color: AppTheme.charcoalInk.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CHỌN PHƯƠNG ÁN XỬ LÝ KHI HẾT HÀNG',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < substitutionOptions.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () => setState(() => _selectedIndex = i),
              child: _PreferenceOptionCard(
                selected: i == _selectedIndex,
                index: i,
                title: substitutionOptions[i],
                subtitle: switch (i) {
                  0 => 'Đề xuất món tương tự giá rẻ hơn hoặc bằng, hoàn lại tiền chênh lệch.',
                  1 => 'Không tự ý thay thế. Bỏ qua món hết hàng và hoàn tiền lập tức vào tài khoản.',
                  _ => 'Tài xế hoặc nhân viên đóng gói sẽ gọi điện xác nhận trước khi quyết định.',
                },
                badge: i == 0 ? 'KHUYÊN DÙNG' : (i == 1 ? 'QUYỀN LỢI' : null),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 18),
          _DynamicSubstitutionSection(selectedIndex: _selectedIndex),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isPaying ? null : _pay,
            icon: const Icon(Icons.check_circle_outline),
            label: _isPaying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Xác nhận & Thanh toán PayOS'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isPaying ? null : () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại Giỏ hàng'),
          ),
        ],
      ),
    );
  }
}

class _PreferenceOptionCard extends StatelessWidget {
  const _PreferenceOptionCard({
    required this.selected,
    required this.index,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final bool selected;
  final int index;
  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(16),
      color: selected ? AppTheme.succulentGreen : Colors.white,
      radius: AppTheme.radiusMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppTheme.primary : AppTheme.outline,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: index == 0 ? AppTheme.primary : AppTheme.ripenedOrange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? AppTheme.primary : AppTheme.charcoalInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.charcoalInk.withValues(alpha: 0.7),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicSubstitutionSection extends ConsumerStatefulWidget {
  const _DynamicSubstitutionSection({required this.selectedIndex});
  final int selectedIndex;

  @override
  ConsumerState<_DynamicSubstitutionSection> createState() =>
      _DynamicSubstitutionSectionState();
}

class _DynamicSubstitutionSectionState
    extends ConsumerState<_DynamicSubstitutionSection> {
  final Map<String, String> _selectedSubstituteId = {};

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final productsAsync = ref.watch(featuredProductsProvider);

    if (productsAsync.isLoading || cartAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final products = productsAsync.value ?? [];
    final cart = cartAsync.valueOrNull;
    final items = cart?.items ?? [];

    if (products.isEmpty) return const SizedBox.shrink();

    List<_SubPair> pairs = [];
    for (final item in items) {
      final orig = products.where((p) => p.id == item.productId).firstOrNull;
      final candidates = products.where((p) {
        if (p.id == item.productId || !p.inStock) return false;
        if (orig != null && p.categoryId == orig.categoryId) return true;
        if (orig != null && p.categoryName == orig.categoryName) return true;
        final words =
            item.productName.toLowerCase().split(' ').where((w) => w.length > 2);
        return words.any((w) => p.name.toLowerCase().contains(w));
      }).toList();

      candidates.sort((a, b) => a.price.compareTo(b.price));

      final isOos = item.stock <= 0 || (orig != null && !orig.inStock);
      final cheaper =
          candidates.where((p) => p.price <= item.unitPrice).toList();

      if (isOos) {
        pairs.add(_SubPair(
          title: 'Hết hàng: ${item.productName}',
          price: item.unitPrice,
          imageUrl: item.imageUrl,
          isOos: true,
          candidates: candidates.take(2).toList(),
        ));
      } else if (cheaper.isNotEmpty) {
        pairs.add(_SubPair(
          title: 'Đang chọn: ${item.productName}',
          price: item.unitPrice,
          imageUrl: item.imageUrl,
          isOos: false,
          candidates: cheaper.take(2).toList(),
        ));
      }
    }

    if (pairs.isEmpty) {
      for (final p in products) {
        if (pairs.length >= 2) break;
        final sameCat = products
            .where((c) =>
                c.id != p.id &&
                c.inStock &&
                c.categoryId == p.categoryId &&
                c.price <= p.price)
            .toList();
        if (sameCat.isNotEmpty) {
          sameCat.sort((a, b) => a.price.compareTo(b.price));
          pairs.add(_SubPair(
            title: 'Sản phẩm trong giỏ: ${p.name}',
            price: p.price,
            imageUrl: p.imageUrl,
            isOos: p.stock <= 0,
            candidates: sameCat.take(2).toList(),
          ));
        }
      }
    }

    if (pairs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: AppTheme.ripenedOrange, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.selectedIndex == 0
                    ? 'ĐỀ XUẤT THAY THẾ'
                    : 'DANH SÁCH MÓN XỬ LÝ THEO TÙY CHỌN',
                style: const TextStyle(
                  color: AppTheme.charcoalInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final pair in pairs) ...[
          _DynamicSubCard(
            pair: pair,
            selectedIndex: widget.selectedIndex,
            selectedSubId: _selectedSubstituteId[pair.title] ??
                (pair.candidates.isNotEmpty ? pair.candidates.first.id : ''),
            onSelectSub: (subId) {
              setState(() => _selectedSubstituteId[pair.title] = subId);
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SubPair {
  const _SubPair({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.isOos,
    required this.candidates,
  });

  final String title;
  final double price;
  final String imageUrl;
  final bool isOos;
  final List<Product> candidates;
}

class _DynamicSubCard extends StatelessWidget {
  const _DynamicSubCard({
    required this.pair,
    required this.selectedIndex,
    required this.selectedSubId,
    required this.onSelectSub,
  });

  final _SubPair pair;
  final int selectedIndex;
  final String selectedSubId;
  final ValueChanged<String> onSelectSub;

  @override
  Widget build(BuildContext context) {
    return OrganicCard(
      padding: const EdgeInsets.all(14),
      color: AppTheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  pair.imageUrl,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 46,
                    height: 46,
                    color: AppTheme.mistGray,
                    child: const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pair.title,
                      style: TextStyle(
                        color:
                            pair.isOos ? AppTheme.coral : AppTheme.charcoalInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        decoration:
                            pair.isOos ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(pair.price),
                      style: const TextStyle(
                        color: AppTheme.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pair.isOos
                      ? AppTheme.coral.withValues(alpha: 0.1)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pair.isOos ? 'Hết hàng' : 'Cùng loại rẻ hơn',
                  style: TextStyle(
                    color: pair.isOos ? AppTheme.coral : AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (selectedIndex == 1) ...[
            const Divider(height: 20, color: AppTheme.mistGray),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.mistGray),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tự động BỎ QUA & Hoàn tiền ngay vào tài khoản nếu hết hàng.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.charcoalInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (selectedIndex == 2) ...[
            const Divider(height: 20, color: AppTheme.mistGray),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.mistGray),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_in_talk_outlined,
                      color: AppTheme.ripenedOrange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài xế sẽ liên hệ qua điện thoại trước để bạn quyết định món thay thế.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.charcoalInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (pair.candidates.isNotEmpty) ...[
            const Divider(height: 20, color: AppTheme.mistGray),
            const Text(
              'Gợi ý thay thế cùng loại từ hệ thống:',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.outline,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final cand in pair.candidates) ...[
              InkWell(
                onTap: () => onSelectSub(cand.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cand.id == selectedSubId
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cand.id == selectedSubId
                          ? AppTheme.primary
                          : AppTheme.mistGray,
                      width: cand.id == selectedSubId ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          cand.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cand.name,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.charcoalInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  formatCurrency(cand.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                if (cand.price < pair.price) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(Tiết kiệm ${formatCurrency(pair.price - cand.price)})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.ripenedOrange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        cand.id == selectedSubId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: cand.id == selectedSubId
                            ? AppTheme.primary
                            : AppTheme.outline,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}
