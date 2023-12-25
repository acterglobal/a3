import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/space/pages/tasks_page.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:acter/features/tasks/dialogs/create_task_list_sheet.dart';
import 'package:acter/features/tasks/pages/task_list_page.dart';
import 'package:acter/features/tasks/pages/tasks_page.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/foundation.dart';
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

  Future<String?> createTaskList(
    String title, {
    String? description,
    List<String>? tasks,
    String? selectSpaceId,
  }) async {
    final params = {
      CreateTaskListSheet.titleKey: title,
    };
    if (description != null) {
      params[CreateTaskListSheet.descKey] = description;
    }
    await fillForm(
      params,
      // we are coming from space, we don't need to select it.
      submitBtnKey: CreateTaskListSheet.submitKey,
      selectSpaceId: selectSpaceId,
    );

    final taskListPage = find.byKey(TaskListPage.pageKey);
    await taskListPage.should(findsOneWidget);
    // // read the actual spaceId
    final page = taskListPage.evaluate().first.widget as TaskListPage;
    final taskListId = page.taskListId;
    final inlineAddBtn =
        find.byKey(Key('task-list-$taskListId-add-task-inline'));
    await inlineAddBtn.should(findsOneWidget);
    if (tasks != null) {
      await inlineAddBtn.tap(); // activate inline add
      final inlineAddTxt =
          find.byKey(Key('task-list-$taskListId-add-task-inline-txt'));
      for (final taskTitle in tasks) {
        await inlineAddTxt.should(findsOneWidget);
        await inlineAddTxt.enterTextWithoutReplace(taskTitle);
        await tester.testTextInput
            .receiveAction(TextInputAction.done); // submit
        await find.text(taskTitle).should(findsOneWidget);
      }
      // close inline add
      final cancelInlineAdd =
          find.byKey(Key('task-list-$taskListId-add-task-inline-cancel'));
      await cancelInlineAdd.should(findsOneWidget);
      await cancelInlineAdd.tap();
    }
    return taskListId;
  }
}

void tasksTests() {
  acterTestWidget('We can enable Tasks for a fresh Space', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    await t.ensureTasksAreEnabled(spaceId);
    await t.gotoSpace(spaceId);
    await t.navigateTo([TabEntry.tasks]); // this worked now
  });

  acterTestWidget('New TaskList & tasks via Space', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      spaceDisplayName: 'Task list via Space Test',
    );
    await t.ensureTasksAreEnabled(spaceId);
    await t.gotoSpace(spaceId, appTab: TabEntry.tasks);
    await t.navigateTo([
      SpaceTasksPage.createTaskKey,
    ]);

    await t.createTaskList(
      'Errands',
      description: 'These are the most important things to do',
      tasks: [
        'Buy milk',
        'Pickup dogs med',
      ],
    );

    await t.gotoSpace(spaceId, appTab: TabEntry.tasks);
    // we see our entry now
    await find.text('Errands').should(findsOneWidget);
    await find.text('Buy milk').should(findsOneWidget);
    await find.text('Pickup dogs med').should(findsOneWidget);

    await t.navigateTo([MainNavKeys.quickJump, QuickJumpKeys.tasks]);
    // we see our entry now
    await find.text('Errands').should(findsOneWidget);
    await find.text('Buy milk').should(findsOneWidget);
    await find.text('Pickup dogs med').should(findsOneWidget);
  });

  acterTestWidget('New TaskList & tasks via all tasks', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      spaceDisplayName: 'Task list via all tasks',
    );
    await t.ensureTasksAreEnabled(spaceId);
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.tasks,
      TasksPage.createNewTaskListKey,
    ]);

    await t.createTaskList(
      'Protest Preparations',
      description: 'Things we have to do for the protest',
      tasks: [
        'Buy markers',
        'Pick up banner',
      ],
      selectSpaceId: spaceId,
    );

    //
    await t.gotoSpace(spaceId, appTab: TabEntry.tasks);
    // we see our entry now
    await find.text('Protest Preparations').should(findsOneWidget);
    await find.text('Buy markers').should(findsOneWidget);
    await find.text('Pick up banner').should(findsOneWidget);
    await t.navigateTo([MainNavKeys.quickJump, QuickJumpKeys.tasks]);
    // we see our entry now
    await find.text('Protest Preparations').should(findsOneWidget);
    await find.text('Buy markers').should(findsOneWidget);
    await find.text('Pick up banner').should(findsOneWidget);
  });

  acterTestWidget('New TaskList & tasks via quickjump', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      spaceDisplayName: 'Task list via quickjump',
    );
    await t.ensureTasksAreEnabled(spaceId);
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.createTaskListAction,
    ]);

    await t.createTaskList(
      'Club Party',
      description: 'Things we have to do for the party on the 11th',
      tasks: [
        'Get drinks',
        'Order chips',
        'Remind everyone of the potluck',
      ],
      selectSpaceId: spaceId,
    );

    //
    await t.gotoSpace(spaceId, appTab: TabEntry.tasks);
    // we see our entry now
    await find.text('Club Party').should(findsOneWidget);
    await find.text('Get drinks').should(findsOneWidget);
    await find.text('Order chips').should(findsOneWidget);
    await find.text('Remind everyone of the potluck').should(findsOneWidget);
    await t.navigateTo([MainNavKeys.quickJump, QuickJumpKeys.tasks]);
    // we see our entry now
    await find.text('Club Party').should(findsOneWidget);
    await find.text('Get drinks').should(findsOneWidget);
    await find.text('Order chips').should(findsOneWidget);
    await find.text('Remind everyone of the potluck').should(findsOneWidget);
  });
}
