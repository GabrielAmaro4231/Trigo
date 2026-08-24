import 'package:flutter/material.dart';

class TransactionKeypad extends StatelessWidget {
  const TransactionKeypad({
    required this.bottomPadding,
    required this.confirmEnabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onConfirm,
    required this.onShowTransactions,
    super.key,
  });

  static const double _topPadding = 6;
  static const double _handleTouchHeight = 24;
  static const double _handleHeight = 4;
  static const double _handleGap = 4;
  static const double _buttonHeight = 64;
  static const double _rowGap = 10;

  static double heightFor(double bottomPadding) {
    return _topPadding +
        _handleTouchHeight +
        _handleGap +
        _buttonHeight * 4 +
        _rowGap * 3 +
        bottomPadding;
  }

  final double bottomPadding;
  final bool confirmEnabled;
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;
  final VoidCallback onShowTransactions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, _topPadding, 18, bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            button: true,
            label: 'Show transactions',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onShowTransactions,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 120) {
                  onShowTransactions();
                }
              },
              child: SizedBox(
                width: double.infinity,
                height: _handleTouchHeight,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const SizedBox(width: 46, height: _handleHeight),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _handleGap),
          _KeypadRow(
            children: <Widget>[
              _KeypadButton(label: '1', onPressed: () => onDigit(1)),
              _KeypadButton(label: '2', onPressed: () => onDigit(2)),
              _KeypadButton(label: '3', onPressed: () => onDigit(3)),
            ],
          ),
          const SizedBox(height: _rowGap),
          _KeypadRow(
            children: <Widget>[
              _KeypadButton(label: '4', onPressed: () => onDigit(4)),
              _KeypadButton(label: '5', onPressed: () => onDigit(5)),
              _KeypadButton(label: '6', onPressed: () => onDigit(6)),
            ],
          ),
          const SizedBox(height: _rowGap),
          _KeypadRow(
            children: <Widget>[
              _KeypadButton(label: '7', onPressed: () => onDigit(7)),
              _KeypadButton(label: '8', onPressed: () => onDigit(8)),
              _KeypadButton(label: '9', onPressed: () => onDigit(9)),
            ],
          ),
          const SizedBox(height: _rowGap),
          _KeypadRow(
            children: <Widget>[
              _KeypadButton(
                icon: Icons.backspace_outlined,
                tooltip: 'Backspace',
                onPressed: onBackspace,
              ),
              _KeypadButton(label: '0', onPressed: () => onDigit(0)),
              _KeypadButton(
                icon: Icons.check_rounded,
                tooltip: 'Confirm',
                isPrimary: true,
                enabled: confirmEnabled,
                onPressed: onConfirm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadRow extends StatelessWidget {
  const _KeypadRow({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: children[0]),
        const SizedBox(width: 10),
        Expanded(child: children[1]),
        const SizedBox(width: 10),
        Expanded(child: children[2]),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.onPressed,
    this.label,
    this.icon,
    this.tooltip,
    this.enabled = true,
    this.isPrimary = false,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final String? tooltip;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final button = SizedBox(
      height: TransactionKeypad._buttonHeight,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.zero,
          backgroundColor: isPrimary
              ? scheme.primary
              : scheme.surface.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.42 : 0.72,
                ),
          foregroundColor: isPrimary ? scheme.onPrimary : scheme.onSurface,
          disabledBackgroundColor: scheme.surface.withValues(alpha: 0.32),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        child: icon == null
            ? Text(label ?? '')
            : Icon(
                icon,
                size: 26,
              ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}
