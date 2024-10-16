import 'package:acter/common/models/keys.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/auth/pages/register_page.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/onboarding/pages/analytics_opt_in_page.dart';
import 'package:acter/features/onboarding/pages/link_email_page.dart';
import 'package:acter/features/onboarding/pages/save_username_page.dart';
import 'package:acter/features/onboarding/pages/upload_avatar_page.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import './appstart.dart';
import 'util.dart';

const defaultRegistrationToken = String.fromEnvironment(
  'REGISTRATION_TOKEN',
  defaultValue: 'TEST_TOKEN',
);

extension ActerLogin on ConvenientTest {
  Future<String> freshAccount({
    String? registrationToken,
    String? displayName,
  }) async {
    final newId = 'it-${const Uuid().v4()}';
    startFreshTestApp(newId);
    await register(
      newId,
      registrationToken: registrationToken,
      displayName: displayName,
    );
    return newId;
  }

  String passwordFor(String username, {String? registrationToken}) {
    if (registrationToken?.isNotEmpty == true) {
      return '$registrationToken:$username';
    } else if (defaultRegistrationToken.isNotEmpty) {
      return '$defaultRegistrationToken:$username';
    } else {
      return username;
    }
  }

  Future<void> register(
    String username, {
    String? registrationToken,
    String? displayName,
  }) async {
    String passwordText =
        passwordFor(username, registrationToken: registrationToken);

    Finder explore = find.byKey(Keys.exploreBtn);
    await explore.should(findsOneWidget);

    await explore.tap();

    Finder login = find.byKey(LoginPageKeys.signUpBtn);
    await login.should(findsOneWidget);

    await login.tap();

    Finder name = find.byKey(RegisterPage.nameField);
    await name.should(findsOneWidget);
    await name.enterTextWithoutReplace(displayName ?? 'Test Account');

    Finder user = find.byKey(RegisterPage.usernameField);
    await user.should(findsOneWidget);
    await user.enterTextWithoutReplace(username);

    Finder password = find.byKey(RegisterPage.passwordField);
    await password.should(findsOneWidget);
    await password.enterTextWithoutReplace(passwordText);

    Finder token = find.byKey(RegisterPage.tokenField);
    await token.should(findsOneWidget);
    await token
        .enterTextWithoutReplace(registrationToken ?? defaultRegistrationToken);

    Finder submitBtn = find.byKey(RegisterPage.submitBtn);
    await tester.ensureVisible(submitBtn);
    await submitBtn.tap();

    Finder copyUsernameBtn = find.byKey(SaveUsernamePage.copyUsernameBtn);
    await tester.ensureVisible(copyUsernameBtn);
    await copyUsernameBtn.tap();

    Finder continueBtn = find.byKey(SaveUsernamePage.continueBtn);
    await tester.ensureVisible(continueBtn);
    await continueBtn.tap();

    Finder email = find.byKey(LinkEmailPage.emailField);
    await email.should(findsOneWidget);
    await email.enterTextWithoutReplace('$username@example.org');

    Finder linkEmailBtn = find.byKey(LinkEmailPage.linkEmailBtn);
    await tester.ensureVisible(linkEmailBtn);
    await linkEmailBtn.tap();

    Finder skipBtn = find.byKey(UploadAvatarPage.skipBtn);
    await tester.ensureVisible(skipBtn);
    await skipBtn.tap();

    Finder doneBtn = find.byKey(AnalyticsOptInPage.skipBtn);
    await tester.ensureVisible(doneBtn);
    await doneBtn.tap();

    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsOneWidget);
  }

  Future<void> logout() async {
    // ensure we do actually have access to the main nav.
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await navigateTo([
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      QuickJumpKeys.settings,
      SettingsMenu.logoutAccount,
      LogoutDialogKeys.confirm,
    ]);

    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsNothing);
  }

  Future<void> tryLogin(
    String username, {
    String? password,
    String? registrationToken,
  }) async {
    await navigateTo([
      Keys.exploreBtn,
      Keys.loginBtn,
    ]);
    await loginFormSubmission(
      username,
      password: password,
      registrationToken: registrationToken,
    );
  }

  Future<void> loginFormSubmission(
    String username, {
    String? password,
    String? registrationToken,
  }) async {
    String passwordText =
        password ?? passwordFor(username, registrationToken: registrationToken);

    Finder user = find.byKey(LoginPageKeys.usernameField);
    await user.should(findsOneWidget);

    await user.enterTextWithoutReplace(username);

    Finder passwordField = find.byKey(LoginPageKeys.passwordField);
    await passwordField.should(findsOneWidget);

    await passwordField.enterTextWithoutReplace(passwordText);

    Finder submitBtn = find.byKey(LoginPageKeys.submitBtn);
    await tester.ensureVisible(submitBtn);
    await submitBtn.should(findsOneWidget);
    await submitBtn.tap();
  }

  Future<void> login(String username, {String? password}) async {
    await tryLogin(username, password: password);
    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsOneWidget);
  }
}
