import 'package:flutter_test/flutter_test.dart';
import 'package:trigo/src/app.dart';

void main() {
  testWidgets('shows the budget setup screen', (tester) async {
    await tester.pumpWidget(const TrigoApp());

    expect(find.text('Set budget'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Until'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
