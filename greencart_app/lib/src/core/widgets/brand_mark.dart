import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.large = false, this.compact = false, super.key});

  final bool large;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = large ? 104.0 : (compact ? 42.0 : 68.0);
    final iconSize = large ? 52.0 : (compact ? 24.0 : 34.0);

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: compact ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(large ? 24 : 14),
            boxShadow: compact ? null : AppTheme.liftedShadow,
          ),
          child: Icon(
            compact ? Icons.shopping_basket : Icons.eco_outlined,
            color: compact ? Colors.white : AppTheme.primary,
            size: iconSize,
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        Text(
          'GreenCart',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 12 : null,
          ),
        ),
      ],
    );
  }
}
