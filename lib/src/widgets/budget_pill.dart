import 'package:flutter/material.dart';

import '../utils/money.dart';
import 'glass_surface.dart';

class BudgetPill extends StatelessWidget {
  const BudgetPill({
    required this.remainingMinorUnits,
    required this.budgetMinorUnits,
    required this.currencySymbol,
    this.contextLabel,
    this.onPressed,
    super.key,
  });

  final int remainingMinorUnits;
  final int budgetMinorUnits;
  final String currencySymbol;
  final String? contextLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final healthColor = _healthColor();
    final foreground =
        ThemeData.estimateBrightnessForColor(healthColor) == Brightness.dark
            ? Colors.white
            : const Color(0xFF091312);
    final formattedRemaining = formatCurrencyMinorUnits(
      remainingMinorUnits,
      symbol: currencySymbol,
    );
    final displayText = contextLabel == null
        ? formattedRemaining
        : '$contextLabel $formattedRemaining';

    return Semantics(
      button: onPressed != null,
      enabled: onPressed != null,
      liveRegion: true,
      label: contextLabel == null ? 'Remaining budget' : '$contextLabel budget',
      value: formattedRemaining,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 248),
        child: GlassSurface(
          radius: 999,
          tint: healthColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: foreground,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                        child: Text(
                          displayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _healthColor() {
    if (remainingMinorUnits <= 0) {
      return const Color(0xFFC62828);
    }

    if (budgetMinorUnits <= 0) {
      return const Color(0xFF2E7D32);
    }

    final ratio =
        (remainingMinorUnits / budgetMinorUnits).clamp(0.0, 1.0).toDouble();

    if (ratio <= 0.25) {
      return const Color(0xFFC62828);
    }

    if (ratio <= 0.65) {
      return const Color(0xFFF9A825);
    }

    return const Color(0xFF2E7D32);
  }
}
