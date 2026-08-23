import 'package:flutter/material.dart';

import 'data/local/app_database.dart';
import 'data/repositories/budget_repository.dart';
import 'features/setup/budget_setup_screen.dart';
import 'features/transactions/transaction_calculator_screen.dart';
import 'models/budget_plan.dart';
import 'theme/trigo_theme.dart';
import 'widgets/trigo_backdrop.dart';

class TrigoApp extends StatelessWidget {
  const TrigoApp({
    this.database,
    super.key,
  });

  final AppDatabase? database;

  @override
  Widget build(BuildContext context) {
    final appDatabase = database ?? AppDatabase.instance;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trigo',
      theme: TrigoTheme.light(),
      darkTheme: TrigoTheme.dark(),
      home: _AppStartupScreen(database: appDatabase),
    );
  }
}

class _AppStartupScreen extends StatefulWidget {
  const _AppStartupScreen({
    required this.database,
  });

  final AppDatabase database;

  @override
  State<_AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<_AppStartupScreen> {
  late Future<BudgetPlan?> _activePlanFuture;
  BudgetPlan? _savedPlan;

  @override
  void initState() {
    super.initState();
    _activePlanFuture = _fetchActivePlan();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BudgetPlan?>(
      future: _activePlanFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupLoadingScreen();
        }

        if (snapshot.hasError) {
          return _StartupErrorScreen(onRetry: _retryLoadActivePlan);
        }

        final plan = _savedPlan ?? snapshot.data;
        if (plan == null) {
          return BudgetSetupScreen(
            database: widget.database,
            onPlanSaved: _openPlan,
          );
        }

        return TransactionCalculatorScreen(
          plan: plan,
          database: widget.database,
        );
      },
    );
  }

  void _openPlan(BudgetPlan plan) {
    setState(() {
      _savedPlan = plan;
    });
  }

  Future<BudgetPlan?> _fetchActivePlan() {
    return BudgetRepository(widget.database).findActivePlan();
  }

  void _retryLoadActivePlan() {
    setState(() {
      _activePlanFuture = _fetchActivePlan();
    });
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TrigoBackdrop(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({
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
