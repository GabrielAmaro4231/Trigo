import 'dart:ui';

import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 8,
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = tint ?? scheme.surface;
    final borderRadius = BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.34 : 0.64),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.68),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
