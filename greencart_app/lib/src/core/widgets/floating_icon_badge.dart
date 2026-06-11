import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FloatingIconBadge extends StatefulWidget {
  const FloatingIconBadge({
    required this.icon,
    this.size = 104,
    this.iconSize = 58,
    this.backgroundColor = AppTheme.succulentGreen,
    this.foregroundColor = AppTheme.primary,
    this.duration = const Duration(milliseconds: 2400),
    super.key,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final Duration duration;

  @override
  State<FloatingIconBadge> createState() => _FloatingIconBadgeState();
}

class _FloatingIconBadgeState extends State<FloatingIconBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        return Transform.translate(
          offset: Offset(0, -7 * value),
          child: Transform.scale(
            scale: 1 + (0.025 * value),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.size * 0.3),
                boxShadow: [
                  BoxShadow(
                    color: widget.foregroundColor.withValues(
                      alpha: 0.14 + (0.08 * value),
                    ),
                    blurRadius: 22 + (10 * value),
                    offset: Offset(0, 10 + (4 * value)),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: widget.foregroundColor,
                size: widget.iconSize,
              ),
            ),
          ),
        );
      },
    );
  }
}
