import 'package:flutter/material.dart';

import 'features/setup/budget_setup_screen.dart';
import 'theme/buckwheat_theme.dart';

class BuckwheatApp extends StatelessWidget {
  const BuckwheatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buckwheat',
      theme: BuckwheatTheme.light(),
      darkTheme: BuckwheatTheme.dark(),
      home: const BudgetSetupScreen(),
    );
  }
}
