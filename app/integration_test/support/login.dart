import 'dart:typed_data';

import 'package:acter/common/models/keys.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/onboarding/pages/protect_privacy_page.dart';
import 'package:acter/features/onboarding/pages/register_page.dart';
import 'package:acter/features/onboarding/pages/save_username_page.dart';
import 'package:acter/features/onboarding/pages/user_avatar_page.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final newId = 'it-${const Uuid().v4().toString()}';
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

    Finder skip = find.byKey(Keys.skipBtn);
    await skip.should(findsOneWidget);

    await skip.tap();

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
    await email.enterTextWithoutReplace('acter@gmail.com');

    Finder linkEmailBtn = find.byKey(LinkEmailPage.linkEmailBtn);
    await tester.ensureVisible(linkEmailBtn);
    await linkEmailBtn.tap();

    // Select User Avatar
    final selectUserAvatarKey = find.byKey(UserAvatarPage.selectUserAvatar);
    final context = tester.element(selectUserAvatarKey);
    final ref = ProviderScope.containerOf(context);
    final imageFile = await convertAssetImageToXFile(
      'assets/images/update_onboard.png',
    );
    Uint8List bytes = await imageFile.readAsBytes();
    final selectedAvatar = PlatformFile(
      path: imageFile.path,
      name: imageFile.name,
      size: bytes.length,
    );
    ref.read(userAvatarProvider.notifier).update((state) => selectedAvatar);

    Finder uploadBtn = find.byKey(UserAvatarPage.uploadBtn);
    await tester.ensureVisible(uploadBtn);
    await uploadBtn.tap();

    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsOneWidget);
  }

  Future<void> logout() async {
    // ensure we do actually have access to the main nav.
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final settingsKey = find.byKey(QuickJumpKeys.settings);
    await settingsKey.should(findsOneWidget);
    await settingsKey.tap();

    final logoutKey = find.byKey(SettingsMenu.logoutAccount);
    await logoutKey.should(findsOneWidget);
    await logoutKey.tap();

    final confirmKey = find.byKey(LogoutDialogKeys.confirm);
    await confirmKey.should(findsOneWidget);
    await confirmKey.tap();

    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsNothing);
  }

  Future<void> tryLogin(String username, {String? registrationToken}) async {
    String passwordText =
        passwordFor(username, registrationToken: registrationToken);

    Finder explore = find.byKey(Keys.exploreBtn);
    await explore.should(findsOneWidget);

    await explore.tap();

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
  }

  Future<void> login(String username) async {
    await tryLogin(username);
    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsOneWidget);
  }
}
