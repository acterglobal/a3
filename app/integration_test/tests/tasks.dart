import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/settings/pages/labs_page.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:app_settings/app_settings.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/util.dart';

extension ActerTasks on ConvenientTest {
  Future<void> ensureTasksAreEnabled(String? spaceId) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final quickJumpKey = find.byKey(MainNavKeys.quickJump);
    await quickJumpKey.should(findsOneWidget);
    await quickJumpKey.tap();

    final tasksKey = find.byKey(QuickJumpKeys.tasks);
    if (tasksKey.evaluate().isNotEmpty) {
      // we have it enabled already, close the screen
      await navigateTo([QuickJumpKeys.settings]);
    } else {
      // not yet activated, let's do it
      await navigateTo([QuickJumpKeys.settings, SettingsMenu.labs]);
      final taskLabsSwitch = find.byKey(SettingsLabsPage.tasksLabSwitch);
      await taskLabsSwitch.should(findsOneWidget);
      await taskLabsSwitch.tap();
    }
    if (spaceId != null) {
      await gotoSpace(spaceId);

      final tasksKey = find.byKey(TabEntry.tasks);
      if (tasksKey.evaluate().isEmpty) {
        // we don't have it activated on this space yet, dp it
        await navigateTo([
          SpaceToolbar.optionsMenu,
          SpaceToolbar.settingsMenu,
          SpaceSettingsMenu.appsMenu,
        ]);

        final taskLabsSwitch = find.byKey(SpaceAppsSettingsPage.tasksSwitch);
        await tester.ensureVisible(taskLabsSwitch);
        await taskLabsSwitch.tap();
      }
    }
  }
}

void tasksTests() {
  acterTestWidget('We can enable Tasks for a fresh Space', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    await t.ensureTasksAreEnabled(spaceId);
    await t.gotoSpace(spaceId);
    await t.navigateTo([TabEntry.tasks]); // this worked now
  });
}
