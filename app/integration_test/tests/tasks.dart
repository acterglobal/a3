import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/space/pages/tasks_page.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:acter/features/tasks/dialogs/create_task_list_sheet.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/util.dart';

extension ActerTasks on ConvenientTest {
  Future<void> ensureTasksAreEnabled(String? spaceId) async {
    await ensureLabEnabled(LabsFeature.tasks);
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

  acterTestWidget('New TaskList via Space', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      spaceDisplayName: 'Task list via Space Test',
    );
    await t.ensureTasksAreEnabled(spaceId);
    await t.gotoSpace(spaceId, appTab: TabEntry.tasks);
    await t.navigateTo([
      SpaceTasksPage.createTaskKey,
    ]);

    await t.fillForm(
      {
        CreateTaskListSheet.titleKey: 'My first task list',
        CreateTaskListSheet.descKey:
            'These are the most important things to do',
      },
      // we are coming from space, we don't need to select it.
      submitBtnKey: CreateTaskListSheet.submitKey,
    );

    //
    await t.gotoSpace(spaceId, appTab: TabEntry.tasks);
    // we see our entry now
    await find.text('My first task list').should(findsOneWidget);
  });
}
