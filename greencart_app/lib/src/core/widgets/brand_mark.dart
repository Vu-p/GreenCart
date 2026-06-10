import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.large = false, super.key});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 104.0 : 68.0;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(large ? 24 : 20),
            boxShadow: AppTheme.liftedShadow,
          ),
          child: Icon(
            Icons.eco_outlined,
            color: AppTheme.primary,
            size: large ? 52 : 34,
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
  }
}
