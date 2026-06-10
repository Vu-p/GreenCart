import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuantityButton extends StatelessWidget {
  const QuantityButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: enabled ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? AppTheme.succulentGreen
            : AppTheme.surfaceContainer,
        foregroundColor: enabled ? AppTheme.primary : AppTheme.outline,
        disabledBackgroundColor: AppTheme.surfaceContainer,
        disabledForegroundColor: AppTheme.outline,
      ),
      icon: Icon(icon),
    );
  }
}
