import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/main.dart' as app;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Can scroll to end of main feed', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Easy example'));
    await tester.pumpAndSettle();

    final listFinder = find.byType(Scrollable);
    final itemFinder = find.textContaining("55");

    // Scroll until the item to be found appears.
    await tester.scrollUntilVisible(
      itemFinder,
      500.0,
      scrollable: listFinder,
      duration: const Duration(milliseconds: 600),
    );
    expect(itemFinder, findsOneWidget);
  });
}
