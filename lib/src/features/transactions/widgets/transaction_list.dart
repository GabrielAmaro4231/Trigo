import 'package:flutter/material.dart';

import '../../../models/expense_tag.dart';
import '../../../models/transaction_entry.dart';
import '../../../utils/dates.dart';
import '../../../utils/money.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({
    required this.transactions,
    required this.tags,
    required this.currencySymbol,
    required this.onDeleteRequested,
    super.key,
  });

  final List<TransactionEntry> transactions;
  final List<ExpenseTag> tags;
  final String currencySymbol;
  final Future<bool> Function(TransactionEntry) onDeleteRequested;

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  String? _revealedTransactionId;

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const _EmptyTransactions();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(4),
      itemCount: widget.transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = widget.transactions[index];

        return _RevealableTransactionRow(
          key: ValueKey<String>('transaction-${transaction.id}'),
          transaction: transaction,
          tag: _tagFor(transaction),
          currencySymbol: widget.currencySymbol,
          isRevealed: transaction.id == _revealedTransactionId,
          onPressed: () => _toggleTransaction(transaction.id),
          onDeletePressed: () => _deleteTransaction(transaction),
        );
      },
    );
  }

  void _toggleTransaction(String transactionId) {
    setState(() {
      _revealedTransactionId =
          _revealedTransactionId == transactionId ? null : transactionId;
    });
  }

  Future<void> _deleteTransaction(TransactionEntry transaction) async {
    final deleted = await widget.onDeleteRequested(transaction);
    if (!mounted || !deleted) {
      return;
    }

    setState(() {
      _revealedTransactionId = null;
    });
  }

  ExpenseTag? _tagFor(TransactionEntry transaction) {
    final tagId = transaction.tagId;
    if (tagId == null) {
      return null;
    }

    for (final tag in widget.tags) {
      if (tag.id == tagId) {
        return tag;
      }
    }

    return null;
  }
}

class _RevealableTransactionRow extends StatelessWidget {
  const _RevealableTransactionRow({
    required this.transaction,
    required this.tag,
    required this.currencySymbol,
    required this.isRevealed,
    required this.onPressed,
    required this.onDeletePressed,
    super.key,
  });

  final TransactionEntry transaction;
  final ExpenseTag? tag;
  final String currencySymbol;
  final bool isRevealed;
  final VoidCallback onPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: colorScheme.onSurface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.10,
        ),
      ),
    );

    return Material(
      color: colorScheme.surface.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.72 : 0.82,
      ),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: _TransactionRow(
        transaction: transaction,
        tag: tag,
        currencySymbol: currencySymbol,
        isRevealed: isRevealed,
        onPressed: onPressed,
        onDeletePressed: onDeletePressed,
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.receipt_long_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.tag,
    required this.currencySymbol,
    required this.isRevealed,
    required this.onPressed,
    required this.onDeletePressed,
  });

  static const double _deleteButtonSize = 48;
  static const double _deleteButtonGap = 12;
  static const double _deleteActionWidth = _deleteButtonSize + _deleteButtonGap;

  final TransactionEntry transaction;
  final ExpenseTag? tag;
  final String currencySymbol;
  final bool isRevealed;
  final VoidCallback onPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = tag?.color ?? theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        height: 48,
        child: Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          tag?.icon ?? Icons.remove_rounded,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            formatShortDate(transaction.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tag == null
                                ? formatClockTime(transaction.createdAt)
                                : '${formatClockTime(transaction.createdAt)} - ${tag!.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.56,
                              ),
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatSignedCurrencyMinorUnits(
                        transaction.amountMinorUnits,
                        symbol: currencySymbol,
                      ),
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerRight,
                child: isRevealed
                    ? SizedBox(
                        width: _deleteActionWidth,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: _deleteButtonGap),
                          child: SizedBox.square(
                            dimension: _deleteButtonSize,
                            child: Tooltip(
                              message: 'Delete transaction',
                              child: IconButton(
                                onPressed: onDeletePressed,
                                style: IconButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
