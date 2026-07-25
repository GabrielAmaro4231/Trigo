import 'package:buckwheat/src/widgets/budget_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the remaining amount without left copy', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetPill(
            remainingMinorUnits: 1234,
            budgetMinorUnits: 2000,
            currencySymbol: r'$',
            contextLabel: 'Today',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text(r'Today $12.34'), findsOneWidget);
    expect(find.textContaining('left'), findsNothing);

    await tester.tap(find.text(r'Today $12.34'));

    expect(tapped, isTrue);
  });
}
