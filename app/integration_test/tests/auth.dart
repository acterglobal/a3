// ignore_for_file: avoid_print

import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/auth/pages/forgot_password.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/login.dart';
import '../support/mail.dart';
import '../support/setup.dart';
import '../support/util.dart';

void authTests() {
  acterTestWidget('registration smoke test', (t) async {
    await t.freshAccount();
  });
  acterTestWidget('register and login test', (t) async {
    final userId = await t.freshAccount();
    await t.logout();
    await t.login(userId);
  });
  acterTestWidget('deactivate account test', (t) async {
    final userId = await t.freshAccount();

    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final settingsKey = find.byKey(QuickJumpKeys.settings);
    await settingsKey.should(findsOneWidget);
    await settingsKey.tap();

    // start deactivation process

    final deactivateBtn = find.byKey(SettingsMenu.deactivateAccount);
    await deactivateBtn.should(findsOneWidget);
    await t.tester.ensureVisible(deactivateBtn);
    await deactivateBtn.tap();

    // enter password
    final deactivatePasswordFld = find.byKey(deactivatePasswordField);
    await deactivatePasswordFld.should(findsOneWidget);
    await deactivatePasswordFld.enterTextWithoutReplace(t.passwordFor(userId));

    // press confirm
    final deactivateCfmBtn = find.byKey(deactivateConfirmBtn);
    await deactivateCfmBtn.should(findsOneWidget);
    await deactivateCfmBtn.tap();

    // we are back on the onboarding screens.
    Finder skip = find.byKey(Keys.exploreBtn);
    await skip.should(findsOneWidget);

    // be back on home.
    await t.tryLogin(userId); // we try
    // but should fail.
    // FIXME: how to check for a failure...
  });
  acterTestWidget('fresh registration has no unauthenticated sessions',
      (t) async {
    await t.freshAccount();
    await t.navigateTo([
      MainNavKeys.activities,
    ]);

    // items _not_ present!
    await find
        .byKey(ActivitiesPage.oneUnverifiedSessionsCard)
        .should(findsNothing);
    await find
        .byKey(ActivitiesPage.unverifiedSessionsCard)
        .should(findsNothing);
  });
  acterTestWidget('ensure unicode registration works', (t) async {
    const testName = "Dwayne 'the 🪨' Johnson";
    await t.freshAccount(displayName: testName);
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.profile,
    ]);

    final displayName = find.byKey(MyProfilePage.displayNameKey);
    await displayName.should(findsOneWidget);
    await find.text(testName).should(findsOneWidget);
  });
  acterTestWidget('password reset', (t) async {
    if (!t.hasMailSupport()) {
      print("MailHog URL missing, can't test mail stuff");
    }
    final userId = await t.freshAccount();
    final emailAddr = '$userId@example.org';

    // we have the activities widget shown
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await t.navigateTo([
      MainNavKeys.activities,
    ]);

    final emailAddrUnconfirmed =
        find.byKey(ActivitiesPage.unconfirmedEmailsKey);
    await t.tester.ensureVisible(emailAddrUnconfirmed);
    await emailAddrUnconfirmed.should(findsOneWidget);

    // Actually confirm
    await t.clickLinkInLatestEmail(
      emailAddr,
      contains: 'Validate your email',
    );

    // Confirm on the App side, too

    await t.confirmEmailAdd(emailAddr, t.passwordFor(userId));

    // the widget is gone on the activities page
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    await t.navigateTo([
      MainNavKeys.activities,
    ]);

    await emailAddrUnconfirmed.should(findsNothing);

    await t.logout();

    await t.navigateTo([
      Keys.exploreBtn,
      Keys.loginBtn,
      LoginPageKeys.forgotPassBtn,
    ]);

    // enter email

    final emailField = find.byKey(ForgotPassword.emailFieldKey);
    await emailField.should(findsOneWidget);
    await emailField.enterTextWithoutReplace(emailAddr);

    final submit = find.byKey(ForgotPassword.submitKey);
    await t.tester.ensureVisible(submit);
    await submit.should(findsOneWidget);
    await submit.tap();

    await t.clickLinkInLatestEmail(
      emailAddr,
      contains: 'Password reset',
      asPost: true, // this is the final click
    );

    final passwordField = find.byKey(ForgotPassword.passwordKey);
    await passwordField.should(findsOneWidget);
    await passwordField.enterTextWithoutReplace('newPasswordFor$userId');

    await t.tester.ensureVisible(submit);
    await submit.should(findsOneWidget);
    await submit.tap();

    // forwards us to the login, let's try it
    await t.loginFormSubmission(userId, password: 'newPasswordFor$userId');
    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsOneWidget);
  });
}
