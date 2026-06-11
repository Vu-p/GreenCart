import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_action_icon.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/features/auth/application/auth_controller.dart';
import 'package:greencart_app/src/features/auth/screens/login_screen.dart';
import 'package:greencart_app/src/features/meal_planner/screens/meal_planner_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const routePath = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFields());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _syncFields() {
    final user = ref.read(authControllerProvider).user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.address ?? '';
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
        );
  }

  Future<void> _logout() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go(LoginScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go(LoginScreen.routePath),
            child: const Text('Back to Login'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const MobilePageTitle(
          title: 'Profile',
          subtitle: 'Manage delivery details',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OrganicActionIcon(
              icon: Icons.notifications_none,
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          OrganicCard(
            radius: AppTheme.radiusLg,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.succulentGreen,
                  child: Text(
                    user.name.isEmpty ? 'G' : user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const OrganicPromoBanner(
            eyebrow: 'GREENCART PRIME',
            title: 'Save \$124.50 this month',
            subtitle: 'Free delivery on every organic order.',
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: () => context.push(MealPlannerScreen.routePath),
            child: const OrganicCard(
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: AppTheme.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Open weekly meal planner',
                      style: TextStyle(
                        color: AppTheme.charcoalInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.outline),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          OrganicCard(
            radius: AppTheme.radiusLg,
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _addressFocusNode.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _addressController,
                  focusNode: _addressFocusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!authState.isLoading) {
                      _save();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: authState.isLoading ? null : _save,
                  icon: authState.isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.save_outlined),
                  label: authState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Save Profile'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
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
