import 'package:flutter/material.dart';

import '../../../models/expense_tag.dart';
import '../../../models/transaction_entry.dart';
import '../../../utils/money.dart';
import '../../../widgets/glass_surface.dart';
import 'transaction_list.dart';

class TransactionsDisplayPane extends StatelessWidget {
  const TransactionsDisplayPane({
    required this.inputMinorUnits,
    required this.currencySymbol,
    required this.tags,
    required this.transactions,
    required this.showTransactions,
    required this.bottomPadding,
    required this.onDeleteTransaction,
    super.key,
  });

  final int inputMinorUnits;
  final String currencySymbol;
  final List<ExpenseTag> tags;
  final List<TransactionEntry> transactions;
  final bool showTransactions;
  final double bottomPadding;
  final Future<bool> Function(TransactionEntry) onDeleteTransaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 16, 18, bottomPadding),
      child: GlassSurface(
        padding: const EdgeInsets.all(18),
        child: SizedBox.expand(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        for (final child in previousChildren)
                          Positioned.fill(child: child),
                        if (currentChild != null)
                          Positioned.fill(child: currentChild),
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.98, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: showTransactions
                      ? TransactionList(
                          key: const ValueKey<String>('transactions'),
                          transactions: transactions,
                          tags: tags,
                          currencySymbol: currencySymbol,
                          onDeleteRequested: onDeleteTransaction,
                        )
                      : _AmountComposer(
                          key: const ValueKey<String>('amount'),
                          amountMinorUnits: inputMinorUnits,
                          currencySymbol: currencySymbol,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountComposer extends StatelessWidget {
  const _AmountComposer({
    required this.amountMinorUnits,
    required this.currencySymbol,
    super.key,
  });

  final int amountMinorUnits;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          formatCurrencyMinorUnits(
            amountMinorUnits,
            symbol: currencySymbol,
          ),
          maxLines: 1,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 76,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
