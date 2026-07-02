import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import 'not_found_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/checkout/screens/checkout_screen.dart';
import '../features/checkout/screens/payment_success_screen.dart';
import '../features/checkout/screens/substitution_screen.dart';
import '../features/checkout/screens/embedded_payment_screen.dart';
import '../features/checkout/screens/payment_cancelled_screen.dart';
import '../features/catalog/screens/home_screen.dart';
import '../features/catalog/screens/product_detail_screen.dart';
import '../features/catalog/screens/search_screen.dart';
import '../features/deals/screens/deals_screen.dart';
import '../features/meal_planner/screens/meal_planner_screen.dart';
import '../features/meal_planner/screens/recipe_detail_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/orders/screens/order_tracking_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/rating_review_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_product_management_screen.dart';
import '../features/admin/screens/admin_category_management_screen.dart';
import '../features/admin/screens/admin_orders_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _searchNavigatorKey = GlobalKey<NavigatorState>();
final _cartNavigatorKey = GlobalKey<NavigatorState>();
final _ordersNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SplashScreen.routePath,
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: HomeScreen.routePath,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: SearchScreen.routePath,
                builder: (context, state) => SearchScreen(
                  initialCategoryId: state.uri.queryParameters['categoryId'],
                  initialCategoryName:
                      state.uri.queryParameters['categoryName'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _cartNavigatorKey,
            routes: [
              GoRoute(
                path: CartScreen.routePath,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _ordersNavigatorKey,
            routes: [
              GoRoute(
                path: OrdersScreen.routePath,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: ProfileScreen.routePath,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: ProductDetailScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: CheckoutScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: SubstitutionScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubstitutionScreen(),
      ),
      GoRoute(
        path: PaymentSuccessScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PaymentSuccessScreen(
          orderId: state.uri.queryParameters['orderId'],
          orderNumber: state.uri.queryParameters['orderNumber'],
        ),
      ),
      GoRoute(
        path: '/checkout/embedded',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => EmbeddedPaymentScreen(
          orderId: state.uri.queryParameters['orderId'] ?? '',
          orderNumber: state.uri.queryParameters['orderNumber'] ?? '',
          checkoutUrl: state.uri.queryParameters['checkoutUrl'] ?? '',
        ),
      ),
      GoRoute(
        path: '/checkout/cancelled',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PaymentCancelledScreen(
          orderId: state.uri.queryParameters['orderId'] ?? '',
          orderNumber: state.uri.queryParameters['orderNumber'] ?? '',
        ),
      ),
      GoRoute(
        path: DealsScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DealsScreen(),
      ),
      GoRoute(
        path: MealPlannerScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MealPlannerScreen(),
      ),
      GoRoute(
        path: RecipeDetailScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            RecipeDetailScreen(recipeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: OrderTrackingScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            OrderTrackingScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RatingReviewScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            RatingReviewScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AdminDashboardScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AdminProductManagementScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminProductManagementScreen(),
      ),
      GoRoute(
        path: AdminCategoryManagementScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminCategoryManagementScreen(),
      ),
      GoRoute(
        path: AdminOrdersScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: NotificationsScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
