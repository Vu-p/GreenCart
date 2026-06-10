import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/catalog/screens/home_screen.dart';
import '../features/catalog/screens/product_detail_screen.dart';
import '../features/catalog/screens/search_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/profile/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.routePath,
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
      GoRoute(
        path: HomeScreen.routePath,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: SearchScreen.routePath,
        builder: (context, state) => SearchScreen(
          initialCategoryId: state.uri.queryParameters['categoryId'],
          initialCategoryName: state.uri.queryParameters['categoryName'],
        ),
      ),
      GoRoute(
        path: ProductDetailScreen.routePath,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: CartScreen.routePath,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: OrdersScreen.routePath,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
