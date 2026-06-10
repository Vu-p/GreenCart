import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/brand_mark.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/auth/application/auth_controller.dart';
import 'package:greencart_app/src/features/catalog/screens/home_screen.dart';

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
    final isAuthenticated = await ref
        .read(authControllerProvider.notifier)
        .restoreSession();

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            children: [
              const Spacer(),
              OrganicCard(
                padding: const EdgeInsets.all(24),
                radius: AppTheme.radiusLg,
                child: const Column(
                  children: [
                    BrandMark(large: true),
                    SizedBox(height: 16),
                    Text(
                      'Smart Grocery Shopping',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.charcoalInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Your daily dose of fresh, organic produce delivered with intelligence.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.outline,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.succulentGreen,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppTheme.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Curated organic picks, clear pricing, and smooth delivery tracking.',
                        style: TextStyle(
                          color: AppTheme.charcoalInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
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
