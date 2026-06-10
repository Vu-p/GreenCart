import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routePath = '/splash';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    final isAuthenticated =
        await ref.read(authControllerProvider.notifier).restoreSession();

    if (!mounted) {
      return;
    }

    if (isAuthenticated) {
      context.go(HomeScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: Column(
            children: [
              const Spacer(),
              const BrandMark(large: true),
              const SizedBox(height: 16),
              const Text(
                'Smart Grocery Shopping',
                style: TextStyle(
                  color: AppTheme.outline,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Your daily dose of fresh, organic produce delivered with intelligence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.outline,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              if (authState.isLoading)
                const LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.mistGray,
                )
              else
                ElevatedButton.icon(
                  onPressed: () => context.go(LoginScreen.routePath),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Get Started'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
