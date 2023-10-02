import 'package:gherkin/gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:acter/common/utils/constants.dart';

const registrationToken = String.fromEnvironment(
  'REGISTRATION_TOKEN',
  defaultValue: '',
);

StepDefinitionGeneric givenWellKnownUserIsLoggedIn() {
  return given1<String, FlutterWorld>(
    r'(kyra|sisko|odo) has logged in',
    (username, context) async {
      String passwordText;
      if (registrationToken.isNotEmpty) {
        passwordText = '$registrationToken:$username';
      } else {
        passwordText = username;
      }

      Finder skip = find.byKey(Keys.skipBtn);
      context.expect(skip, findsOneWidget);

      await context.world.appDriver.tap(skip);
      await context.world.appDriver.waitForAppToSettle();

      Finder login = find.byKey(Keys.loginBtn);
      context.expect(login, findsOneWidget);

      await context.world.appDriver.tap(login);
      await context.world.appDriver.waitForAppToSettle();

      Finder user = find.byKey(LoginPageKeys.usernameField);
      context.expect(user, findsOneWidget);

      await context.world.appDriver.enterText(user, username);

      Finder password = find.byKey(LoginPageKeys.passwordField);
      context.expect(password, findsOneWidget);

      await context.world.appDriver.enterText(password, passwordText);

      Finder submitBtn = find.byKey(LoginPageKeys.submitBtn);
      context.expect(submitBtn, findsOneWidget);
      await context.world.appDriver.tap(submitBtn);
      await context.world.appDriver.waitUntil(
        () async {
          await context.world.appDriver.waitForAppToSettle();
          return context.world.appDriver.isPresent(
            // seeing a main navigation means we are in!
            context.world.appDriver.findBy(Keys.mainNav, FindType.key),
          );
        },
        timeout: const Duration(seconds: 15),
        pollInterval: const Duration(milliseconds: 100),
      );
    },
    configuration: StepDefinitionConfiguration()
      ..timeout = const Duration(seconds: 30),
  );
}
