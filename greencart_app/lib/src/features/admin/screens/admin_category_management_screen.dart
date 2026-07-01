import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/organic_card.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/models/category.dart';
import '../data/admin_repository.dart';

class AdminCategoryManagementScreen extends ConsumerStatefulWidget {
  const AdminCategoryManagementScreen({super.key});

  static const routePath = '/admin/categories';

  @override
  ConsumerState<AdminCategoryManagementScreen> createState() =>
      _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState
    extends ConsumerState<AdminCategoryManagementScreen> {
  void _showCategoryForm([GroceryCategory? category]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CategoryFormDialog(category: category),
    ).then((success) {
      if (success == true) {
        ref.invalidate(categoriesProvider);
      }
    });
  }

  Future<void> _deleteCategory(GroceryCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This will fail if the category has products.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(adminRepositoryProvider).deleteCategory(category.id);
        ref.invalidate(categoriesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          // If category has products, the backend returns conflict. Show the actual message if possible
          String msg = e.toString();
          if (msg.contains('has products')) {
            msg = 'Cannot delete category: It still contains products.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryForm(),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OrganicCard(
                  padding: const EdgeInsets.all(12),
                  radius: AppTheme.radiusMd,
                  child: Row(
                    children: [
                      // Category Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          category.imageUrl != null && category.imageUrl!.isNotEmpty
                              ? category.imageUrl!
                              : 'https://images.unsplash.com/photo-1542838132-92c53300491e',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: AppTheme.mistGray,
                            child: const Icon(Icons.category_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.charcoalInk,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                        onPressed: () => _showCategoryForm(category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteCategory(category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  const _CategoryFormDialog({this.category});

  final GroceryCategory? category;

  @override
  ConsumerState<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _imageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _imageController = TextEditingController(text: widget.category?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final img = _imageController.text.trim();
      final imgUrl = img.isNotEmpty ? img : null;

      if (widget.category == null) {
        await repo.createCategory(
          name: _nameController.text.trim(),
          imageUrl: imgUrl,
        );
      } else {
        await repo.updateCategory(
          widget.category!.id,
          name: _nameController.text.trim(),
          imageUrl: imgUrl,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'Leave empty for default',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 40),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
