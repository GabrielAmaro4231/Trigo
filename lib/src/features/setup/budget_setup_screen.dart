import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/budget_plan.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/trigo_backdrop.dart';
import '../transactions/transaction_calculator_screen.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final TextEditingController _budgetController = TextEditingController();

  late DateTime _endDate;
  int _budgetMinorUnits = 0;

  @override
  void initState() {
    super.initState();
    _endDate = oneCalendarMonthFrom(DateTime.now());
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canContinue = _budgetMinorUnits > 0;

    return Scaffold(
      body: TrigoBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Set budget',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassSurface(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Amount',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.72),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _budgetController,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            onChanged: _handleBudgetChanged,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                            decoration: const InputDecoration(
                              prefixText: '$defaultCurrencySymbol ',
                              hintText: '0.00',
                              suffixIcon: Icon(Icons.payments_rounded),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _pickEndDate,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.event_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Until',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.72),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatShortDate(_endDate),
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.58),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: canContinue ? _continueToTransactions : null,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Continue'),
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

  void _handleBudgetChanged(String value) {
    setState(() {
      _budgetMinorUnits = parseCurrencyInputToMinorUnits(value);
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = picked;
    });
  }

  Future<void> _continueToTransactions() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TransactionCalculatorScreen(
          plan: BudgetPlan(
            budgetMinorUnits: _budgetMinorUnits,
            startDate: DateTime(now.year, now.month, now.day),
            endDate: _endDate,
          ),
        ),
      ),
    );
  }
}
