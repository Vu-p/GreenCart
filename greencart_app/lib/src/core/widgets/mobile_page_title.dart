import 'package:flutter/material.dart';

class MobilePageTitle extends StatelessWidget {
  const MobilePageTitle({
    required this.title,
    required this.subtitle,
    this.titleStyle,
    super.key,
  });

  final String title;
  final String subtitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle ?? Theme.of(context).textTheme.headlineLarge,
        ),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
