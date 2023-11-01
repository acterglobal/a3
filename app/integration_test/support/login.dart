import 'package:acter/common/models/keys.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/onboarding/pages/register_page.dart';
import 'package:acter/features/profile/model/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import './appstart.dart';

const registrationToken = String.fromEnvironment(
  'REGISTRATION_TOKEN',
  defaultValue: 'asdf',
);

extension ActerLogin on ConvenientTest {
  Future<String> freshAccount() async {
    final newId = 'it-${const Uuid().v4().toString()}';
    startFreshTestApp(newId);
    await register(newId);
    return newId;
  }

  Future<void> register(String username) async {
    String passwordText;
    if (registrationToken.isNotEmpty) {
      passwordText = '$registrationToken:$username';
    } else {
      passwordText = username;
    }

    Finder skip = find.byKey(Keys.skipBtn);
    await skip.should(findsOneWidget);

    await skip.tap();

    Finder login = find.byKey(LoginPageKeys.signUpBtn);
    await login.should(findsOneWidget);

    await login.tap();

    Finder name = find.byKey(RegisterPage.nameField);
    await name.should(findsOneWidget);
    await name.enterTextWithoutReplace('Test Account');

    Finder user = find.byKey(RegisterPage.usernameField);
    await user.should(findsOneWidget);
    await user.enterTextWithoutReplace(username);

    Finder password = find.byKey(RegisterPage.passwordField);
    await password.should(findsOneWidget);
    await password.enterTextWithoutReplace(passwordText);

    Finder token = find.byKey(RegisterPage.tokenField);
    await token.should(findsOneWidget);
    await token.enterTextWithoutReplace(registrationToken);

    Finder submitBtn = find.byKey(RegisterPage.submitBtn);
    await tester.ensureVisible(submitBtn);
    await submitBtn.tap();
    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsOneWidget);
  }

  Future<void> logout() async {
    // ensure we do actually have access to the main nav.
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final profileKey = find.byKey(QuickJumpKeys.profile);
    await profileKey.should(findsOneWidget);
    await profileKey.tap();

    final logoutKey = find.byKey(MyProfileKeys.logout);
    await logoutKey.should(findsOneWidget);
    await logoutKey.tap();

    final confirmKey = find.byKey(LogoutDialogKeys.confirm);
    await confirmKey.should(findsOneWidget);
    await confirmKey.tap();

    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsNothing);
  }

  Future<void> login(String username) async {
    String passwordText;
    if (registrationToken.isNotEmpty) {
      passwordText = '$registrationToken:$username';
    } else {
      passwordText = username;
    }

    Finder skip = find.byKey(Keys.skipBtn);
    await skip.should(findsOneWidget);

    await skip.tap();

    Finder login = find.byKey(Keys.loginBtn);
    await login.should(findsOneWidget);

    await login.tap();

    Finder user = find.byKey(LoginPageKeys.usernameField);
    await user.should(findsOneWidget);

    await user.enterTextWithoutReplace(username);

    Finder password = find.byKey(LoginPageKeys.passwordField);
    await password.should(findsOneWidget);

    await password.enterTextWithoutReplace(passwordText);

    Finder submitBtn = find.byKey(LoginPageKeys.submitBtn);
    await submitBtn.should(findsOneWidget);
    await submitBtn.tap();
    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsOneWidget);
  }
}
