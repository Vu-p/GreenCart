import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'src/screens/home_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/product_detail_screen.dart';
import 'src/screens/profile_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/screens/search_screen.dart';
import 'src/screens/splash_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: GreenCartApp()));
}

class GreenCartApp extends ConsumerWidget {
  const GreenCartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'GreenCart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

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
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
