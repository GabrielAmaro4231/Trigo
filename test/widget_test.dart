import 'package:buckwheat/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the budget setup screen', (tester) async {
    await tester.pumpWidget(const BuckwheatApp());

    expect(find.text('Set budget'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Until'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
