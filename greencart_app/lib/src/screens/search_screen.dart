import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../products/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/product_card.dart';

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

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _categoryName = widget.initialCategoryName;
    _productsFuture ??= _loadProducts();
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
        );
  }

  void _search() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          if (_categoryName != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(_categoryName!),
                avatar: const Icon(Icons.category_outlined),
                onDeleted: _clearCategory,
              ),
            ),
          ],
          const SizedBox(height: 22),
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
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) =>
                    ProductCard(product: products[index]),
                itemCount: products.length,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppNavBar(currentIndex: 1),
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
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 54),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
