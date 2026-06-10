import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OrganicCard extends StatelessWidget {
  const OrganicCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
    this.radius = AppTheme.radiusMd,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppTheme.cardDecoration(color: color, radius: radius),
      child: child,
    );
  }
}
