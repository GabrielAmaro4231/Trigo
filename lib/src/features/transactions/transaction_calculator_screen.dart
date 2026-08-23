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
import '../../widgets/glass_surface.dart';
import '../../widgets/trigo_backdrop.dart';

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

  late final ExpenseTagRepository _tagRepository;
  late final TransactionRepository _transactionRepository;
  late List<ExpenseTag> _tags;
  String? _selectedTagId;

  int _inputMinorUnits = 0;
  bool _isLoading = true;
  bool _showTransactions = false;
  bool _showTagPicker = false;

  @override
  void initState() {
    super.initState();
    _tagRepository = ExpenseTagRepository(widget.database);
    _transactionRepository = TransactionRepository(widget.database);
    _tags = defaultExpenseTags();
    unawaited(_loadPersistedState());
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
    return dailyBudgetMinorUnitsForDate(widget.plan, DateTime.now());
  }

  int get _todayAvailableMinorUnits {
    return availableBudgetMinorUnitsThroughDate(
      widget.plan,
      DateTime.now(),
      _transactions,
    );
  }

  int get _todayStartingAvailableMinorUnits {
    final now = DateTime.now();
    final yesterday = dateOnly(now).subtract(const Duration(days: 1));
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

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topOffset = _budgetPillTopOffset(viewPadding.top);
    final bottomOffset = math.max(viewPadding.bottom, 12.0);
    final keypadHeight = _Keypad.heightFor(bottomOffset);
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
                    child: _DisplayPane(
                      inputMinorUnits: _inputMinorUnits,
                      currencySymbol: widget.plan.currencySymbol,
                      tags: _tags,
                      transactions: _transactions,
                      showTransactions: _showTransactions,
                      bottomPadding: _showTransactions ? 10 : keypadHeight + 10,
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
                      child: _Keypad(
                        bottomPadding: bottomOffset,
                        confirmEnabled: _inputMinorUnits > 0,
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
                        child: _FloatingTagPicker(
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
                    child: _TagShortcutButton(
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
      _inputMinorUnits = math.min(_inputMinorUnits * 10 + digit, 99999999999);
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
    if (_inputMinorUnits == 0) {
      return;
    }

    unawaited(HapticFeedback.mediumImpact());

    final now = DateTime.now();
    final transaction = TransactionEntry(
      id: now.microsecondsSinceEpoch.toString(),
      amountMinorUnits: -_inputMinorUnits,
      createdAt: now,
      tagId: _selectedTagId,
    );

    try {
      await _transactionRepository.insert(transaction);
    } catch (_) {
      if (mounted) {
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
      _showTransactions = false;
      _showTagPicker = false;
    });
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

  Future<void> _openTagManager() async {
    final updatedTags = await showModalBottomSheet<List<ExpenseTag>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _TagManagerSheet(tags: _tags);
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
      tags = defaultExpenseTags();
      transactions = <TransactionEntry>[];
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _tags = tags;
      // SQLite returns a fixed-length list. The screen prepends new entries.
      _transactions = List<TransactionEntry>.of(transactions);
      _isLoading = false;
    });
  }
}

class _DisplayPane extends StatelessWidget {
  const _DisplayPane({
    required this.inputMinorUnits,
    required this.currencySymbol,
    required this.tags,
    required this.transactions,
    required this.showTransactions,
    required this.bottomPadding,
  });

  final int inputMinorUnits;
  final String currencySymbol;
  final List<ExpenseTag> tags;
  final List<TransactionEntry> transactions;
  final bool showTransactions;
  final double bottomPadding;

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
                      ? _TransactionList(
                          key: const ValueKey<String>('transactions'),
                          transactions: transactions,
                          tags: tags,
                          currencySymbol: currencySymbol,
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

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.transactions,
    required this.tags,
    required this.currencySymbol,
    super.key,
  });

  final List<TransactionEntry> transactions;
  final List<ExpenseTag> tags;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _EmptyTransactions();
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: transactions.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
      ),
      itemBuilder: (context, index) {
        return _TransactionRow(
          transaction: transactions[index],
          tag: _tagFor(transactions[index]),
          currencySymbol: currencySymbol,
        );
      },
    );
  }

  ExpenseTag? _tagFor(TransactionEntry transaction) {
    final tagId = transaction.tagId;
    if (tagId == null) {
      return null;
    }

    for (final tag in tags) {
      if (tag.id == tagId) {
        return tag;
      }
    }

    return null;
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
  });

  final TransactionEntry transaction;
  final ExpenseTag? tag;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = tag?.color ?? theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
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
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagShortcutButton extends StatelessWidget {
  const _TagShortcutButton({
    required this.tag,
    required this.onPressed,
  });

  final ExpenseTag? tag;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTag = tag;
    final foreground = selectedTag == null
        ? theme.colorScheme.onSurface
        : _foregroundFor(selectedTag.color);
    final label = selectedTag?.name ?? 'Tag';

    return Tooltip(
      message: selectedTag == null ? 'Choose tag' : 'Selected tag: $label',
      child: SizedBox(
        width: 136,
        height: 52,
        child: GlassSurface(
          radius: 999,
          tint: selectedTag?.color,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      selectedTag?.icon ?? Icons.sell_rounded,
                      color: foreground,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
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
}

class _FloatingTagPicker extends StatelessWidget {
  const _FloatingTagPicker({
    required this.tags,
    required this.selectedTagId,
    required this.onSelected,
    required this.onManage,
  });

  final List<ExpenseTag> tags;
  final String? selectedTagId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 268, maxHeight: 284),
      child: GlassSurface(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.sell_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tags',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onManage,
                  icon: const Icon(Icons.tune_rounded),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Manage tags',
                ),
              ],
            ),
            Flexible(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tags.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.95,
                ),
                itemBuilder: (context, index) {
                  final tag = tags[index];

                  return _FloatingTagChip(
                    tag: tag,
                    selected: tag.id == selectedTagId,
                    onPressed: () {
                      onSelected(tag.id == selectedTagId ? null : tag.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingTagChip extends StatelessWidget {
  const _FloatingTagChip({
    required this.tag,
    required this.selected,
    required this.onPressed,
  });

  final ExpenseTag tag;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        selected ? _foregroundFor(tag.color) : theme.colorScheme.onSurface;
    final iconColor = selected ? foreground : _foregroundFor(tag.color);
    final iconBackground =
        selected ? foreground.withValues(alpha: 0.16) : tag.color;

    return Tooltip(
      message: selected ? 'Clear ${tag.name}' : tag.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? tag.color
                  : theme.colorScheme.surface.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? tag.color : tag.color.withValues(alpha: 0.28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: SizedBox.square(
                      dimension: 22,
                      child: Icon(
                        tag.icon,
                        color: iconColor,
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      tag.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagManagerSheet extends StatefulWidget {
  const _TagManagerSheet({
    required this.tags,
  });

  final List<ExpenseTag> tags;

  @override
  State<_TagManagerSheet> createState() => _TagManagerSheetState();
}

class _TagManagerSheetState extends State<_TagManagerSheet> {
  late List<ExpenseTag> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List<ExpenseTag>.of(widget.tags);
  }

  bool get _canCreateTag {
    return _tags.length < maxExpenseTagCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.74;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: <Widget>[
                  Text(
                    'Tags',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_tags.length}/$maxExpenseTagCount',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.56,
                      ),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _canCreateTag ? _createTag : null,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'New tag',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop(_tags);
                    },
                    icon: const Icon(Icons.check_rounded),
                    tooltip: 'Done',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _tags.length,
                separatorBuilder: (context, index) {
                  return Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                  );
                },
                itemBuilder: (context, index) {
                  final tag = _tags[index];

                  return _ManagedTagRow(
                    tag: tag,
                    position: index + 1,
                    canMoveUp: index > 0,
                    canMoveDown: index < _tags.length - 1,
                    onEdit: () => _editTag(index),
                    onMoveUp: () => _moveTag(index, index - 1),
                    onMoveDown: () => _moveTag(index, index + 1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTag() async {
    if (!_canCreateTag) {
      return;
    }

    final tag = await showModalBottomSheet<ExpenseTag>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const _TagEditorSheet();
      },
    );

    if (!mounted || tag == null) {
      return;
    }

    setState(() {
      _tags.add(tag);
    });
  }

  Future<void> _editTag(int index) async {
    final tag = await showModalBottomSheet<ExpenseTag>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _TagEditorSheet(tag: _tags[index]);
      },
    );

    if (!mounted || tag == null) {
      return;
    }

    setState(() {
      _tags[index] = tag;
    });
  }

  void _moveTag(int fromIndex, int toIndex) {
    if (toIndex < 0 || toIndex >= _tags.length) {
      return;
    }

    setState(() {
      final tag = _tags.removeAt(fromIndex);
      _tags.insert(toIndex, tag);
    });
  }
}

class _ManagedTagRow extends StatelessWidget {
  const _ManagedTagRow({
    required this.tag,
    required this.position,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onEdit,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final ExpenseTag tag;
  final int position;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          _TagAvatar(tag: tag, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tag.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Position $position',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            tooltip: 'Move up',
          ),
          IconButton(
            onPressed: canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            tooltip: 'Move down',
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }
}

class _TagEditorSheet extends StatefulWidget {
  const _TagEditorSheet({
    this.tag,
  });

  final ExpenseTag? tag;

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  late final TextEditingController _nameController;
  late IconData _selectedIcon;
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    final tag = widget.tag;
    final fallbackTag = defaultExpenseTags().first;

    _selectedIcon = tag?.icon ?? fallbackTag.icon;
    _selectedColorValue = tag?.colorValue ?? fallbackTag.colorValue;
    _nameController = TextEditingController(text: tag?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _nameController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    widget.tag == null ? 'New tag' : 'Edit tag',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _canSave ? _save : null,
                    icon: const Icon(Icons.check_rounded),
                    tooltip: 'Save',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(_selectedIcon),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Icon',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tagIconOptions().length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final option = tagIconOptions()[index];
                  final selected = option.icon == _selectedIcon;

                  return _IconChoiceButton(
                    option: option,
                    selected: selected,
                    color: Color(_selectedColorValue),
                    onPressed: () {
                      setState(() {
                        _selectedIcon = option.icon;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Color',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              _ColorWheelButton(
                color: Color(_selectedColorValue),
                onPressed: _openColorWheel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openColorWheel() async {
    final color = await showModalBottomSheet<Color>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ColorWheelSheet(
          initialColor: Color(_selectedColorValue),
        );
      },
    );

    if (!mounted || color == null) {
      return;
    }

    setState(() {
      _selectedColorValue = color.toARGB32();
    });
  }

  void _save() {
    if (!_canSave) {
      return;
    }

    Navigator.of(context).pop(
      ExpenseTag(
        id: widget.tag?.id ?? 'tag_${DateTime.now().microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        colorValue: _selectedColorValue,
      ),
    );
  }
}

class _IconChoiceButton extends StatelessWidget {
  const _IconChoiceButton({
    required this.option,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final TagIconOption option;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        selected ? _foregroundFor(color) : theme.colorScheme.onSurface;

    return Tooltip(
      message: option.name,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(option.icon),
        color: foreground,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? color
              : theme.colorScheme.surface.withValues(alpha: 0.56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _ColorWheelButton extends StatelessWidget {
  const _ColorWheelButton({
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(color);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox.square(
              dimension: 32,
              child: Icon(
                Icons.palette_rounded,
                color: foreground,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Choose color'),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }
}

class _ColorWheelSheet extends StatefulWidget {
  const _ColorWheelSheet({
    required this.initialColor,
  });

  final Color initialColor;

  @override
  State<_ColorWheelSheet> createState() => _ColorWheelSheetState();
}

class _ColorWheelSheetState extends State<_ColorWheelSheet> {
  late HSVColor _color;

  @override
  void initState() {
    super.initState();
    _color = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Color',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(_color.toColor());
                  },
                  icon: const Icon(Icons.check_rounded),
                  tooltip: 'Done',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: _ColorWheelPicker(
                color: _color,
                onChanged: (color) {
                  setState(() {
                    _color = color;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Icon(Icons.light_mode_rounded),
                Expanded(
                  child: Slider(
                    value: _color.value,
                    min: 0.16,
                    onChanged: (value) {
                      setState(() {
                        _color = _color.withValue(value);
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorWheelPicker extends StatelessWidget {
  const _ColorWheelPicker({
    required this.color,
    required this.onChanged,
  });

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 260.0;
        final dimension = math.min(maxWidth, 260.0);
        final size = Size.square(dimension);

        return GestureDetector(
          onPanDown: (details) {
            _selectColor(details.localPosition, size);
          },
          onPanUpdate: (details) {
            _selectColor(details.localPosition, size);
          },
          child: SizedBox.square(
            dimension: dimension,
            child: CustomPaint(
              painter: _ColorWheelPainter(color: color),
            ),
          ),
        );
      },
    );
  }

  void _selectColor(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final vector = localPosition - center;
    final distance = math.min(vector.distance, radius);
    final saturation = (distance / radius).clamp(0.0, 1.0).toDouble();
    final radians = math.atan2(vector.dy, vector.dx);
    final hue = (radians * 180 / math.pi + 360) % 360;

    onChanged(color.withHue(hue).withSaturation(saturation));
  }
}

class _ColorWheelPainter extends CustomPainter {
  const _ColorWheelPainter({
    required this.color,
  });

  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    final huePaint = Paint()
      ..shader = const SweepGradient(
        colors: <Color>[
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(bounds);
    canvas.drawCircle(center, radius, huePaint);

    final saturationPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white,
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(bounds);
    canvas.drawCircle(center, radius, saturationPaint);

    if (color.value < 1) {
      final valuePaint = Paint()
        ..color = Colors.black.withValues(alpha: 1 - color.value);
      canvas.drawCircle(center, radius, valuePaint);
    }

    final selectedRadians = color.hue * math.pi / 180;
    final selectedOffset = Offset(
      math.cos(selectedRadians) * color.saturation * radius,
      math.sin(selectedRadians) * color.saturation * radius,
    );
    final selectedCenter = center + selectedOffset;

    canvas
      ..drawCircle(
        selectedCenter,
        9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      )
      ..drawCircle(
        selectedCenter,
        6,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TagAvatar extends StatelessWidget {
  const _TagAvatar({
    required this.tag,
    this.size = 26,
  });

  final ExpenseTag tag;
  final double size;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(tag.color);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tag.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          tag.icon,
          color: foreground,
          size: size * 0.52,
        ),
      ),
    );
  }
}

Color _foregroundFor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : const Color(0xFF091312);
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.bottomPadding,
    required this.confirmEnabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onConfirm,
    required this.onShowTransactions,
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
      height: _Keypad._buttonHeight,
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
