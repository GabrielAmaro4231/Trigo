import 'package:flutter/material.dart';

class BuckwheatBackdrop extends StatelessWidget {
  const BuckwheatBackdrop({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? const <Color>[
            Color(0xFF101413),
            Color(0xFF0E2524),
            Color(0xFF2A2110),
          ]
        : const <Color>[
            Color(0xFFF7FAF3),
            Color(0xFFDCEFEB),
            Color(0xFFFFF2CB),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
