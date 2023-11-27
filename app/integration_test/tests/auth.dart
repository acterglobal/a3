import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/profile/pages/my_profile_page.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/login.dart';
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
    Finder skip = find.byKey(Keys.skipBtn);
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
    find.byKey(ActivitiesPage.oneUnverifiedSessionsCard).should(findsNothing);
    find.byKey(ActivitiesPage.unverifiedSessionsCard).should(findsNothing);
  });
  acterTestWidget('ensure unicode registration works', (t) async {
    const testName = "Dwayne 'the 🪨' Johnson";
    await t.freshAccount(displayName: testName);
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.profile,
    ]);

    final displayName = find.byKey(MyProfile.displayNameKey);
    await displayName.should(findsOneWidget);
    await find.text(testName).should(findsOneWidget);
  });
}
