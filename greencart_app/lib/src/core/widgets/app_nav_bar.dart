import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/screens/cart_screen.dart';
import '../../features/catalog/screens/home_screen.dart';
import '../../features/catalog/screens/search_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../theme/app_theme.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.liftedShadow,
          ),
          child: NavigationBar(
            height: 68,
            selectedIndex: currentIndex,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: AppTheme.succulentGreen,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppTheme.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search, color: AppTheme.primary),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(
                  Icons.shopping_cart,
                  color: AppTheme.primary,
                ),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primary),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppTheme.primary),
                label: 'Profile',
              ),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go(HomeScreen.routePath);
                case 1:
                  context.go(SearchScreen.routePath);
                case 2:
                  context.go(CartScreen.routePath);
                case 3:
                  context.go(OrdersScreen.routePath);
                case 4:
                  context.go(ProfileScreen.routePath);
              }
            },
          ),
        ),
      ),
    );
  }
}
