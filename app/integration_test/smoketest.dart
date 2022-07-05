import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/foundation.dart';

import 'package:effektio/main.dart' as app;

void main() {
  // final IntegrationTestWidgetsFlutterBinding binding =
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('failing test example', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await app.startApp();
    await tester.pumpAndSettle();
    Finder bottomBar = find.byKey(const Key('bottom-bar'));
    expect(tester.any(bottomBar), true);
    expect(2 + 2, equals(4));
  });
}
