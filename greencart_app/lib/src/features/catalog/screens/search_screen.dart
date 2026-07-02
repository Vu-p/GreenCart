import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_state_message.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';
import 'package:greencart_app/src/features/catalog/models/product.dart';
import 'package:greencart_app/src/features/catalog/widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    this.initialCategoryId,
    this.initialCategoryName,
    super.key,
  });

  static const routePath = '/search';

  final String? initialCategoryId;
  final String? initialCategoryName;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String? _categoryId;
  String? _categoryName;
  Future<List<Product>>? _productsFuture;

  String? _sortBy; // 'price_asc', 'price_desc', 'name_asc'
  bool _isDealOnly = false;
  bool _isOrganicOnly = false;
  bool _inStockOnly = false;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _categoryName = widget.initialCategoryName;
    _productsFuture ??= _loadProducts();
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategoryId != widget.initialCategoryId ||
        oldWidget.initialCategoryName != widget.initialCategoryName) {
      _categoryId = widget.initialCategoryId;
      _categoryName = widget.initialCategoryName;
      _productsFuture = _loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() {
    return ref.read(productRepositoryProvider).getProducts(
          keyword: _searchController.text,
          categoryId: _categoryId,
          isDeal: _isDealOnly ? true : null,
          isOrganic: _isOrganicOnly ? true : null,
          inStock: _inStockOnly ? true : null,
          maxPrice: _maxPrice,
          sortBy: _sortBy,
        );
  }

  void _search() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _productsFuture = _loadProducts();
    });
  }

  void _clearCategory() {
    setState(() {
      _categoryId = null;
      _categoryName = null;
      _productsFuture = _loadProducts();
    });
  }

  void _resetFilters() {
    setState(() {
      _sortBy = null;
      _isDealOnly = false;
      _isOrganicOnly = false;
      _inStockOnly = false;
      _maxPrice = null;
      _productsFuture = _loadProducts();
    });
  }

  void _showFilterSheet() {
    String? tempSortBy = _sortBy;
    bool tempDeal = _isDealOnly;
    bool tempOrganic = _isOrganicOnly;
    bool tempInStock = _inStockOnly;
    double? tempMaxPrice = _maxPrice;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: Color(0xFF006A38)),
                        const SizedBox(width: 8),
                        Text(
                          'Bộ lọc & Sắp xếp (Filter & Sort)',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Sắp xếp theo (Sort by)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('🌟 Ưu đãi nổi bật'),
                          selected: tempSortBy == null,
                          selectedColor: const Color(0xFFE9F5EE),
                          onSelected: (_) => setSheetState(() => tempSortBy = null),
                        ),
                        ChoiceChip(
                          label: const Text('⬇️ Giá thấp đến cao'),
                          selected: tempSortBy == 'price_asc',
                          selectedColor: const Color(0xFFE9F5EE),
                          onSelected: (_) => setSheetState(() => tempSortBy = 'price_asc'),
                        ),
                        ChoiceChip(
                          label: const Text('⬆️ Giá cao đến thấp'),
                          selected: tempSortBy == 'price_desc',
                          selectedColor: const Color(0xFFE9F5EE),
                          onSelected: (_) => setSheetState(() => tempSortBy = 'price_desc'),
                        ),
                        ChoiceChip(
                          label: const Text('🔤 Tên A-Z'),
                          selected: tempSortBy == 'name_asc',
                          selectedColor: const Color(0xFFE9F5EE),
                          onSelected: (_) => setSheetState(() => tempSortBy = 'name_asc'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mức giá tối đa (Max Price)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tất cả mức giá'),
                          selected: tempMaxPrice == null,
                          selectedColor: const Color(0xFFE9F5EE),
                          onSelected: (_) => setSheetState(() => tempMaxPrice = null),
                        ),
                        ChoiceChip(
                          label: const Text('≤ 50.000 đ'),
                          selected: tempMaxPrice == 50000,
                          selectedColor: const Color(0xFFE9F5EE),
                          onSelected: (_) => setSheetState(() => tempMaxPrice = 50000),
                        ),
                        ChoiceChip(
                          label: const Text('≤ 100.000 đ'),
                          selected: tempMaxPrice == 100000,
                          selectedColor: const Color(0xFFE9F5EE),
                          onSelected: (_) => setSheetState(() => tempMaxPrice = 100000),
                        ),
                        ChoiceChip(
                          label: const Text('≤ 200.000 đ'),
                          selected: tempMaxPrice == 200000,
                          selectedColor: const Color(0xFFE9F5EE),
                          onSelected: (_) => setSheetState(() => tempMaxPrice = 200000),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tiêu chí sản phẩm (Filters)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    CheckboxListTile(
                      value: tempInStock,
                      onChanged: (v) => setSheetState(() => tempInStock = v ?? false),
                      title: const Text('📦 Chỉ hiện sản phẩm Còn hàng (In Stock)'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      value: tempOrganic,
                      onChanged: (v) => setSheetState(() => tempOrganic = v ?? false),
                      title: const Text('🌱 Chỉ hiện thực phẩm Hữu cơ (100% Organic)'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      value: tempDeal,
                      onChanged: (v) => setSheetState(() => tempDeal = v ?? false),
                      title: const Text('🔥 Chỉ hiện món Đang giảm giá (Special Deals)'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _resetFilters();
                            },
                            child: const Text('Xóa bộ lọc'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006A38),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              setState(() {
                                _sortBy = tempSortBy;
                                _isDealOnly = tempDeal;
                                _isOrganicOnly = tempOrganic;
                                _inStockOnly = tempInStock;
                                _maxPrice = tempMaxPrice;
                                _productsFuture = _loadProducts();
                              });
                            },
                            child: const Text('Áp dụng bộ lọc'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Search',
          subtitle: 'Find fresh groceries fast',
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _search,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF006A38),
                    side: const BorderSide(color: Color(0xFF006A38)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _showFilterSheet,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                    (_sortBy != null || _isDealOnly || _isOrganicOnly || _inStockOnly || _maxPrice != null)
                        ? '⚙️ Bộ lọc đang bật (Đã lọc)'
                        : '⚙️ Bộ lọc & Sắp xếp (Filter & Sort)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              if (_sortBy != null || _isDealOnly || _isOrganicOnly || _inStockOnly || _maxPrice != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Xóa bộ lọc',
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFFE9F5EE)),
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.filter_alt_off, color: Color(0xFF006A38), size: 20),
                ),
              ],
            ],
          ),
          if (_categoryName != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(_categoryName!),
                avatar: const Icon(Icons.category_outlined),
                onDeleted: _clearCategory,
                backgroundColor: AppTheme.succulentGreen,
                deleteIconColor: AppTheme.primary,
                side: BorderSide.none,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _StateMessage(
                  icon: Icons.wifi_off_outlined,
                  title: 'Could not load products',
                  actionLabel: 'Retry',
                  onAction: _search,
                );
              }

              final products = snapshot.data ?? const <Product>[];
              if (products.isEmpty) {
                return _StateMessage(
                  icon: Icons.search_off_outlined,
                  title: 'No products match your search',
                  actionLabel: 'Clear search',
                  onAction: () {
                    _searchController.clear();
                    _clearCategory();
                  },
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (context, index) =>
                    ProductCard(product: products[index]),
                itemCount: products.length,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return OrganicStateMessage(
      icon: icon,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      topPadding: 80,
    );
  }
}
