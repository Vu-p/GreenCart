import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/theme/app_theme.dart';
import 'package:greencart_app/src/core/widgets/auth_scaffold.dart';
import 'package:greencart_app/src/core/widgets/brand_mark.dart';
import 'package:greencart_app/src/core/widgets/organic_card.dart';
import 'package:greencart_app/src/features/auth/application/auth_controller.dart';
import 'package:greencart_app/src/features/catalog/screens/home_screen.dart';

import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const routePath = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
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
        .register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      context.go(HomeScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthScaffold(
      children: [
        const BrandMark(),
        const SizedBox(height: 18),
        Text(
          'Create your GreenCart account',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 28),
        OrganicCard(
          radius: AppTheme.radiusLg,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Full name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Name must be at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    hintText: 'Email address',
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!authState.isLoading) {
                      _submit();
                    }
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: 'Password',
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
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
              : const Icon(Icons.person_add_alt_1),
          label: authState.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Sign Up'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account?'),
            TextButton(
              onPressed: () => context.go(LoginScreen.routePath),
              child: const Text('Login'),
            ),
          ],
        ),
      ],
    );
  }
}
