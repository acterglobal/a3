import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:effektio/main.dart' as app;
import 'package:effektio/common/utils/constants.dart';

Future<void> signInAs(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String username,
) async {
  Finder bottomBar = find.byKey(Keys.bottomBar);
  expect(bottomBar, findsOneWidget);

  Finder newsSection = find.byKey(Keys.newsSectionBtn);
  expect(newsSection, findsOneWidget);

  await tester.tap(newsSection);
  await tester.pumpAndSettle();

  Finder sidebar = find.byKey(Keys.sidebarBtn);
  expect(sidebar, findsOneWidget);

  await tester.tap(sidebar);
  await tester.pumpAndSettle();

  Finder login = find.byKey(Keys.loginBtn);
  expect(login, findsOneWidget);

  await tester.tap(login);
  await tester.pumpAndSettle();

  Finder user = find.byKey(LoginScreenKeys.usernameField);
  expect(user, findsOneWidget);

  await tester.enterText(user, username);

  Finder password = find.byKey(LoginScreenKeys.passwordField);
  expect(password, findsOneWidget);

  await tester.enterText(password, username);

  Finder submitBtn = find.byKey(LoginScreenKeys.submitBtn);
  expect(submitBtn, findsOneWidget);
  await tester.tap(submitBtn);
  await tester.pumpAndSettle();

  // we are back on the news screen
  Finder successBar = find.byKey(LoginScreenKeys.snackbarSuccess);
  expect(successBar, findsOneWidget);
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // testWidgets('bottom bar shows up', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await app.startApp();
  //   await tester.pumpAndSettle();
  //   Finder bottomBar = find.byKey(Keys.bottomBar);
  //   expect(bottomBar, findsOneWidget);
  // });

  testWidgets('kyras can login', (WidgetTester tester) async {
    await app.startFreshTestApp('kyra_can_login_smoketest');
    await tester.pumpAndSettle();
    await signInAs(tester, binding, 'kyra');
  });
}
