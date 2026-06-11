import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OrganicActionIcon extends StatelessWidget {
  const OrganicActionIcon({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.succulentGreen,
        foregroundColor: AppTheme.primary,
      ),
      icon: Icon(icon),
    );
  }
}
