import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'organic_card.dart';

class OrganicStateMessage extends StatelessWidget {
  const OrganicStateMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.topPadding = 0,
    super.key,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: OrganicCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.succulentGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
