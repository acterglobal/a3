import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/login.dart';

void authTests() {
  tTestWidgets('registration smoke test', (t) async {
    await t.freshAccount();
  });
  tTestWidgets('register and login test', (t) async {
    final userId = await t.freshAccount();
    await t.logout();
    await t.login(userId);
  });
  tTestWidgets('deactivate account test', (t) async {
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
}
