import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _floatAnimation = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
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
                child: Column(
                  children: [
                    _FloatingBrandMark(animation: _floatAnimation),
                    const SizedBox(height: 16),
                    const Text(
                      'Smart Grocery Shopping',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.charcoalInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
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

class _FloatingBrandMark extends StatelessWidget {
  const _FloatingBrandMark({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final lift = -8.0 * animation.value;
        final shadowOpacity = 0.08 + (0.06 * animation.value);
        final shadowBlur = 18.0 + (10.0 * animation.value);
        final scale = 1.0 + (0.025 * animation.value);

        return Column(
          children: [
            Transform.translate(
              offset: Offset(0, lift),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(
                          alpha: shadowOpacity,
                        ),
                        blurRadius: shadowBlur,
                        offset: Offset(0, 10 + (4 * animation.value)),
                      ),
                      BoxShadow(
                        color: AppTheme.charcoalInk.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    color: AppTheme.primary,
                    size: 52,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'GreenCart',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      },
    );
  }
}
