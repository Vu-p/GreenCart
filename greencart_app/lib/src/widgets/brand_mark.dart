import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.large = false, super.key});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 112.0 : 72.0;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(large ? 28 : 22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.charcoalInk.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.shopping_cart_outlined,
            color: AppTheme.primary,
            size: large ? 56 : 36,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'GreenCart',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ],
    );
  }
}
