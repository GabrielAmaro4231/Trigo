import 'package:flutter/material.dart';

import 'features/setup/budget_setup_screen.dart';
import 'theme/trigo_theme.dart';

class TrigoApp extends StatelessWidget {
  const TrigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trigo',
      theme: TrigoTheme.light(),
      darkTheme: TrigoTheme.dark(),
      home: const BudgetSetupScreen(),
    );
  }
}
