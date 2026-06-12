import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/auth_scaffold.dart';
import 'package:greencart_app/src/core/widgets/brand_mark.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/auth/application/auth_controller.dart';
import 'package:greencart_app/src/features/catalog/screens/home_screen.dart';

import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'name@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (success && mounted) {
      context.go(HomeScreen.routePath);
    }
  }

  Future<void> _googleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final success = await ref
        .read(authControllerProvider.notifier)
        .loginWithGoogle();

    if (success && mounted) {
      context.go(HomeScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthScaffold(
      children: [
        const SizedBox(height: 4),
        const BrandMark(),
        const SizedBox(height: 12),
        Text(
          'Freshness delivered to your door.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 30),
        OrganicCard(
          radius: AppTheme.radiusLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Email Address',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    hintText: 'name@example.com',
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    TextButton(
                      onPressed: null,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!authState.isLoading) {
                      _submit();
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    return null;
                  },
                ),
                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: authState.isLoading ? null : _submit,
                  icon: authState.isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.login),
                  label: authState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'OR CONTINUE WITH',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.outline,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _googleLogin,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Google'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.grid_view),
                label: const Text('Apple'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            TextButton(
              onPressed: () => context.go(RegisterScreen.routePath),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ],
    );
  }
}
