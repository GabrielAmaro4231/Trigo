import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/expense_tag_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../models/budget_plan.dart';
import '../../models/expense_tag.dart';
import '../../models/transaction_entry.dart';
import '../../utils/budget_pacing.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../widgets/budget_pill.dart';
import '../../widgets/trigo_backdrop.dart';
import 'widgets/display_pane.dart';
import 'widgets/keypad.dart';
import 'widgets/tag_manager_sheet.dart';
import 'widgets/tag_picker.dart';

class TransactionCalculatorScreen extends StatefulWidget {
  const TransactionCalculatorScreen({
    required this.plan,
    required this.database,
    super.key,
  });

  final BudgetPlan plan;
  final AppDatabase database;

  @override
  State<TransactionCalculatorScreen> createState() =>
      _TransactionCalculatorScreenState();
}

class _TransactionCalculatorScreenState
    extends State<TransactionCalculatorScreen> {
  List<TransactionEntry> _transactions = <TransactionEntry>[];

  Timer? _dayChangeTimer;
  late final AppLifecycleListener _lifecycleListener;
  late final ExpenseTagRepository _tagRepository;
  late final TransactionRepository _transactionRepository;
  late DateTime _currentDate;
  late List<ExpenseTag> _tags;
  String? _selectedTagId;

  int _inputMinorUnits = 0;
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isSavingTransaction = false;
  bool _showTransactions = false;
  bool _showTagPicker = false;

  @override
  void initState() {
    super.initState();
    _tagRepository = ExpenseTagRepository(widget.database);
    _transactionRepository = TransactionRepository(widget.database);
    _currentDate = dateOnly(DateTime.now());
    _tags = defaultExpenseTags();
    _lifecycleListener = AppLifecycleListener(
      onResume: _refreshCurrentDate,
    );
    _scheduleDayChange();
    unawaited(_loadPersistedState());
  }

  @override
  void dispose() {
    _dayChangeTimer?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  ExpenseTag? get _selectedTag {
    final selectedTagId = _selectedTagId;
    if (selectedTagId == null) {
      return null;
    }

    for (final tag in _tags) {
      if (tag.id == selectedTagId) {
        return tag;
      }
    }

    return null;
  }

  int get _dailyBudgetMinorUnits {
    return dailyBudgetMinorUnitsForDate(widget.plan, _currentDate);
  }

  int get _todayAvailableMinorUnits {
    return availableBudgetMinorUnitsThroughDate(
      widget.plan,
      _currentDate,
      _transactions,
    );
  }

  int get _todayStartingAvailableMinorUnits {
    final yesterday = _currentDate.subtract(const Duration(days: 1));
    final carryoverMinorUnits = availableBudgetMinorUnitsThroughDate(
      widget.plan,
      yesterday,
      _transactions,
    );

    return _dailyBudgetMinorUnits + carryoverMinorUnits;
  }

  int get _remainingMinorUnits {
    return _todayAvailableMinorUnits;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: TrigoBackdrop(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_hasLoadError) {
      return _TransactionLoadErrorScreen(
        onRetry: _retryLoadPersistedState,
      );
    }

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topOffset = _budgetPillTopOffset(viewPadding.top);
    final bottomOffset = math.max(viewPadding.bottom, 12.0);
    final keypadHeight = TransactionKeypad.heightFor(bottomOffset);
    final showTagPickerBesideShortcut = screenWidth >= 448;
    final tagPickerRight = showTagPickerBesideShortcut ? 164.0 : 16.0;
    final tagPickerBottom =
        keypadHeight + (showTagPickerBesideShortcut ? 12.0 : 76.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        _handleBackNavigation(didPop);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: TrigoBackdrop(
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: topOffset),
                    child: BudgetPill(
                      remainingMinorUnits: _remainingMinorUnits,
                      budgetMinorUnits: _todayStartingAvailableMinorUnits,
                      currencySymbol: widget.plan.currencySymbol,
                      contextLabel: 'Today',
                      onPressed: _toggleTransactions,
                    ),
                  ),
                  Expanded(
                    child: TransactionsDisplayPane(
                      inputMinorUnits: _inputMinorUnits,
                      currencySymbol: widget.plan.currencySymbol,
                      tags: _tags,
                      transactions: _transactions,
                      showTransactions: _showTransactions,
                      bottomPadding: _showTransactions ? 10 : keypadHeight + 10,
                      onDeleteTransaction: _requestDeleteTransaction,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  offset:
                      _showTransactions ? const Offset(0, 1.08) : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showTransactions ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: _showTransactions,
                      child: TransactionKeypad(
                        bottomPadding: bottomOffset,
                        confirmEnabled:
                            _inputMinorUnits > 0 && !_isSavingTransaction,
                        onDigit: _appendDigit,
                        onBackspace: _backspace,
                        onConfirm: _confirmTransaction,
                        onShowTransactions: _showTransactionList,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: tagPickerRight,
                bottom: tagPickerBottom,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    scale: _showTagPicker && !_showTransactions ? 1 : 0.96,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _showTagPicker && !_showTransactions ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_showTagPicker || _showTransactions,
                        child: FloatingTagPicker(
                          tags: _tags,
                          selectedTagId: _selectedTagId,
                          onSelected: _selectTag,
                          onManage: _openManagedTagsFromPicker,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: keypadHeight + 18,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _showTransactions ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _showTransactions,
                    child: TagShortcutButton(
                      tag: _selectedTag,
                      onPressed: _toggleTagPicker,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _budgetPillTopOffset(double topInset) {
    if (topInset >= 54) {
      return topInset - 38;
    }

    if (topInset >= 36) {
      return topInset - 22;
    }

    return 12;
  }

  void _appendDigit(int digit) {
    unawaited(HapticFeedback.selectionClick());

    setState(() {
      _inputMinorUnits = math.min(
        _inputMinorUnits * 10 + digit,
        maximumSupportedMinorUnits,
      );
      _showTransactions = false;
      _showTagPicker = false;
    });
  }

  void _backspace() {
    unawaited(HapticFeedback.selectionClick());

    setState(() {
      _inputMinorUnits = _inputMinorUnits ~/ 10;
      _showTransactions = false;
      _showTagPicker = false;
    });
  }

  Future<void> _confirmTransaction() async {
    if (_inputMinorUnits == 0 || _isSavingTransaction) {
      return;
    }

    final now = DateTime.now();
    final transaction = TransactionEntry(
      id: now.microsecondsSinceEpoch.toString(),
      amountMinorUnits: -_inputMinorUnits,
      createdAt: now,
      tagId: _selectedTagId,
    );

    setState(() {
      _isSavingTransaction = true;
    });

    try {
      await _transactionRepository.insert(transaction);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSavingTransaction = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the transaction.'),
          ),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _transactions.insert(
        0,
        transaction,
      );
      _inputMinorUnits = 0;
      _selectedTagId = null;
      _isSavingTransaction = false;
      _showTransactions = false;
      _showTagPicker = false;
    });
    unawaited(HapticFeedback.mediumImpact());
  }

  void _toggleTransactions() {
    unawaited(HapticFeedback.lightImpact());

    setState(() {
      _showTransactions = !_showTransactions;
      _showTagPicker = false;
    });
  }

  void _showTransactionList() {
    if (_showTransactions) {
      return;
    }

    _toggleTransactions();
  }

  void _handleBackNavigation(bool didPop) {
    if (didPop) {
      return;
    }

    if (_showTransactions || _showTagPicker) {
      setState(() {
        _showTransactions = false;
        _showTagPicker = false;
      });
      return;
    }

    if (Theme.of(context).platform == TargetPlatform.android) {
      unawaited(SystemNavigator.pop());
    }
  }

  void _toggleTagPicker() {
    unawaited(HapticFeedback.selectionClick());

    setState(() {
      _showTagPicker = !_showTagPicker;
      _showTransactions = false;
    });
  }

  void _selectTag(String? tagId) {
    unawaited(HapticFeedback.selectionClick());

    setState(() {
      _selectedTagId = tagId;
      _showTagPicker = false;
      _showTransactions = false;
    });
  }

  Future<void> _openManagedTagsFromPicker() async {
    setState(() {
      _showTagPicker = false;
    });

    await _openTagManager();
  }

  Future<bool> _requestDeleteTransaction(
    TransactionEntry transaction,
  ) async {
    final formattedAmount = formatCurrencyMinorUnits(
      transaction.amountMinorUnits.abs(),
      symbol: widget.plan.currencySymbol,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        final colorScheme = dialogTheme.colorScheme;
        final actionShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        );
        final actionTextStyle = dialogTheme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        );
        final cancelButtonStyle = FilledButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
          foregroundColor: colorScheme.onSurface,
          shape: actionShape,
          side: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.18),
          ),
          textStyle: actionTextStyle,
        );
        final deleteButtonStyle = FilledButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          shape: actionShape,
          side: BorderSide(color: colorScheme.error),
          textStyle: actionTextStyle,
        );

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('Delete transaction?'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '$formattedAmount will be returned to today\'s available '
                  'budget.',
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: cancelButtonStyle,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: deleteButtonStyle,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                          label: const Text('Delete'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return false;
    }

    try {
      await _transactionRepository.deleteById(transaction.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the transaction.'),
          ),
        );
      }
      return false;
    }

    if (!mounted) {
      return false;
    }

    setState(() {
      _transactions.removeWhere((entry) => entry.id == transaction.id);
    });
    unawaited(HapticFeedback.mediumImpact());
    return true;
  }

  Future<void> _openTagManager() async {
    final updatedTags = await showModalBottomSheet<List<ExpenseTag>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return TagManagerSheet(tags: _tags);
      },
    );

    if (!mounted || updatedTags == null || updatedTags.isEmpty) {
      return;
    }

    try {
      await _tagRepository.replaceAll(updatedTags);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the tags.'),
          ),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _tags = updatedTags;
      if (!_tags.any((tag) => tag.id == _selectedTagId)) {
        _selectedTagId = null;
      }
    });
  }

  Future<void> _loadPersistedState() async {
    late final List<ExpenseTag> tags;
    late final List<TransactionEntry> transactions;

    try {
      tags = await _tagRepository.findOrSeedDefaults();
      transactions = await _transactionRepository.findAllNewestFirst();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadError = true;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _tags = tags;
      // SQLite returns a fixed-length list. The screen prepends new entries.
      _transactions = List<TransactionEntry>.of(transactions);
      _isLoading = false;
      _hasLoadError = false;
    });
  }

  void _retryLoadPersistedState() {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });
    unawaited(_loadPersistedState());
  }

  void _refreshCurrentDate() {
    if (!mounted) {
      return;
    }

    final currentDate = dateOnly(DateTime.now());

    if (currentDate != _currentDate) {
      setState(() {
        _currentDate = currentDate;
      });
    }

    _scheduleDayChange();
  }

  void _scheduleDayChange() {
    _dayChangeTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final delay = tomorrow.difference(now) + const Duration(milliseconds: 100);
    _dayChangeTimer = Timer(delay, _refreshCurrentDate);
  }
}

class _TransactionLoadErrorScreen extends StatelessWidget {
  const _TransactionLoadErrorScreen({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TrigoBackdrop(
        child: Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ),
      ),
    );
  }
}
