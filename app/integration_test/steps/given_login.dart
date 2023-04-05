import 'package:gherkin/gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:acter/common/utils/constants.dart';

StepDefinitionGeneric givenWellKnownUserIsLoggedIn() {
  return given1<String, FlutterWorld>(
    r'(kyra|sisko|odo) has logged in',
    (username, context) async {
      // FIXME: add feature to always have a loginBtn.
      // Finder bottomBar = find.byKey(Keys.bottomBar);
      // context.expect(bottomBar, findsOneWidget);

      // Finder newsSection = find.byKey(Keys.newsSectionBtn);
      // context.expect(newsSection, findsOneWidget);

      // await context.world.appDriver.tap(newsSection);
      // await context.world.appDriver.waitForAppToSettle();

      // Finder sidebar = find.byKey(Keys.sidebarBtn);
      // context.expect(sidebar, findsOneWidget);

      // await context.world.appDriver.tap(sidebar);
      // await context.world.appDriver.waitForAppToSettle();

      Finder login = find.byKey(Keys.loginBtn);
      context.expect(login, findsOneWidget);

      await context.world.appDriver.tap(login);
      await context.world.appDriver.waitForAppToSettle();

      Finder user = find.byKey(LoginPageKeys.usernameField);
      context.expect(user, findsOneWidget);

      await context.world.appDriver.enterText(user, username);

      Finder password = find.byKey(LoginPageKeys.passwordField);
      context.expect(password, findsOneWidget);

      await context.world.appDriver.enterText(password, username);

      Finder submitBtn = find.byKey(LoginPageKeys.submitBtn);
      context.expect(submitBtn, findsOneWidget);
      await context.world.appDriver.tap(submitBtn);
      await context.world.appDriver.waitForAppToSettle(
        duration: const Duration(
          milliseconds: 500,
        ),
      );

      // we are back on the news screen
      Finder successBar = find.byKey(LoginPageKeys.snackbarSuccess);
      context.expect(successBar, findsOneWidget);
      // implement your code
    },
  );
}
