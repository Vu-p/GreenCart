import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/animated_entrance.dart';
import 'package:greencart_app/src/core/widgets/mobile_page_title.dart';
import 'package:greencart_app/src/core/widgets/organic_action_icon.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/core/widgets/organic_promo_banner.dart';
import 'package:greencart_app/src/core/widgets/section_header.dart';
import 'package:greencart_app/src/features/auth/application/auth_controller.dart';
import 'package:greencart_app/src/features/auth/screens/login_screen.dart';
import 'package:greencart_app/src/features/meal_planner/screens/meal_planner_screen.dart';
import 'package:greencart_app/src/features/checkout/screens/map_address_picker_screen.dart';

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
          title: 'GreenCart',
          subtitle: 'Profile & Settings',
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          AnimatedEntrance(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1),
                      duration: const Duration(milliseconds: 620),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.succulentGreen,
                        child: Text(
                          user.name.isEmpty ? 'G' : user.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 2,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.check, color: Colors.white, size: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AnimatedEntrance(
            delay: Duration(milliseconds: 120),
            child: OrganicPromoBanner(
              eyebrow: 'GREENCART PRIME',
              title: 'Save \$124.50 this month',
              subtitle: 'Free delivery on every organic order.',
              icon: Icons.local_shipping_outlined,
            ),
          ),
          const SizedBox(height: 20),
          const AnimatedEntrance(
            delay: Duration(milliseconds: 200),
            child: SectionHeader(title: 'Account & Privacy'),
          ),
          const SizedBox(height: 10),
          AnimatedEntrance(
            delay: const Duration(milliseconds: 260),
            child: OrganicCard(
              padding: EdgeInsets.zero,
              radius: AppTheme.radiusLg,
              child: Column(
                children: [
                  const _SettingsRow(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Account Settings',
                  ),
                  const Divider(height: 1, color: AppTheme.mistGray),
                  const _SettingsRow(
                    icon: Icons.bookmark_border,
                    label: 'Saved Addresses',
                  ),
                  const Divider(height: 1, color: AppTheme.mistGray),
                  const _SettingsRow(
                    icon: Icons.credit_card,
                    label: 'Payment Methods',
                  ),
                  const Divider(height: 1, color: AppTheme.mistGray),
                  _SettingsRow(
                    icon: Icons.restaurant_menu,
                    label: 'Meal Planner',
                    onTap: () => context.push(MealPlannerScreen.routePath),
                  ),
                  if (user.role == 'Admin') ...[
                    const Divider(height: 1, color: AppTheme.mistGray),
                    _SettingsRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin Dashboard',
                      onTap: () => context.push('/admin'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const AnimatedEntrance(
            delay: Duration(milliseconds: 340),
            child: SectionHeader(title: 'Delivery Profile'),
          ),
          const SizedBox(height: 10),
          AnimatedEntrance(
            delay: const Duration(milliseconds: 400),
            child: OrganicCard(
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
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: const Color(0xFF006A38),
                      side: const BorderSide(color: Color(0xFF006A38), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => MapAddressPickerScreen(
                            initialAddress: _addressController.text,
                          ),
                        ),
                      );
                      if (picked != null && picked.isNotEmpty) {
                        setState(() {
                          _addressController.text = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text(
                      '🗺 Chọn vị trí trên Bản đồ (Pick on Map)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
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
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.charcoalInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }
}
