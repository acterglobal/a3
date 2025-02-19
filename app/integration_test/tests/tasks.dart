import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/settings/pages/apps_settings_page.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:acter/features/tasks/pages/task_list_details_page.dart';
import 'package:acter/features/tasks/pages/tasks_list_page.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/util.dart';

typedef TaskListCreateResult = ({
  String spaceId,
  String taskListId,
});

extension ActerTasks on ConvenientTest {
  Future<void> ensureTasksAreEnabled(String? spaceId) async {
    if (spaceId != null) {
      await gotoSpace(spaceId);

      final tasksKey = find.byKey(Key(TabEntry.tasks.name));
      if (tasksKey.evaluate().isEmpty) {
        // we don't have it activated on this space yet, do it
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

  Future<void> addTasks(
    String taskListId,
    List<String> tasks,
  ) async {
    final inlineAddTxt =
        find.byKey(Key('task-list-$taskListId-add-task-inline-txt'));
    for (final taskTitle in tasks) {
      await inlineAddTxt.should(findsOneWidget);
      await inlineAddTxt.enterTextWithoutReplace(taskTitle);
      await tester.testTextInput.receiveAction(TextInputAction.done); // submit
      await find.text(taskTitle).should(findsOneWidget);
    }
  }

  Future<String> createTaskList(
    String title, {
    String? description,
    List<String>? tasks,
    String? selectSpaceId,
  }) async {
    final params = {
      CreateUpdateTaskList.titleKey: title,
    };
    if (description != null) {
      params[CreateUpdateTaskList.descKey] = description;
    }
    await fillForm(
      params,
      // we are coming from space, we don't need to select it.
      submitBtnKey: CreateUpdateTaskList.submitKey,
      selectSpaceId: selectSpaceId,
    );

    final taskListPage = find.byKey(TaskListDetailPage.pageKey);
    await taskListPage.should(findsOneWidget);
    // // read the actual spaceId
    final page = taskListPage.evaluate().first.widget as TaskListDetailPage;
    final taskListId = page.taskListId;

    final inlineAddBtn =
        find.byKey(Key('task-list-$taskListId-add-task-inline'));
    await inlineAddBtn.should(findsOneWidget);
    await ensureHasBackButton();
    if (tasks != null) {
      await inlineAddBtn.tap(); // activate inline add
      await addTasks(taskListId, tasks);
      // close inline add
      final cancelInlineAdd =
          find.byKey(Key('task-list-$taskListId-add-task-inline-cancel'));
      await cancelInlineAdd.should(findsOneWidget);
      await cancelInlineAdd.tap();
    }
    return taskListId;
  }

  Future<TaskListCreateResult> freshWithTasks(
    List<String> tasks, {
    String? listTitle,
    String? spaceDisplayName,
    String? userDisplayName,
  }) async {
    final spaceId = await freshAccountWithSpace(
      spaceDisplayName: spaceDisplayName ?? 'Tasks',
      userDisplayName: userDisplayName,
    );
    await ensureTasksAreEnabled(spaceId);
    await gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));
    await navigateTo([
      TasksListPage.createNewTaskListKey,
    ]);

    final taskListId = await createTaskList(
      listTitle ?? 'Errands',
      tasks: tasks,
    );
    return (spaceId: spaceId, taskListId: taskListId);
  }

  Future<void> renameTask(String newTitle) async {
    // final titleField = find.byKey(TaskInfo.titleField);
    // await titleField.should(findsOneWidget);
    // await titleField.tap(); // switches into edit mode

    // final textField = find.descendant(
    //   of: titleField,
    //   matching:
    //       find.byWidgetPredicate((Widget widget) => widget is TextFormField),
    // );
    // await textField.should(findsOneWidget);
    // await textField.replaceText(newTitle);
    //
    // await tester.testTextInput.receiveAction(TextInputAction.done); // submit
    // textfield is gone
    // await textField.should(findsNothing);
  }

  Future<void> replaceTaskBody(String newBody) async {
    // final taskBodyEdit = find.byKey(TaskBody.editKey);
    // await taskBodyEdit.should(findsOneWidget);
    // await taskBodyEdit.tap(); // switch into edit
    //
    // final taskBodyEditor = find.byKey(TaskBody.editorKey);
    //
    // await taskBodyEditor.should(findsOneWidget);
    // await taskBodyEditor.enterTextWithoutReplace(newBody);
    //
    // final saveBtn = find.byKey(TaskBody.saveEditKey);
    // await tester.ensureVisible(saveBtn);
    // await saveBtn.tap(); // switch off edit more
    //
    // // dialog closed
    // await saveBtn.should(findsNothing);
  }
}

void tasksTests() {
  acterTestWidget('We can enable Tasks for a fresh Space', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    await t.ensureTasksAreEnabled(spaceId);
    await t.gotoSpace(spaceId);
    await t.navigateTo([Key(TabEntry.tasks.name)]); // this worked now
  });

  acterTestWidget('New TaskList & tasks via Space', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      spaceDisplayName: 'Task list via Space Test',
    );
    await t.ensureTasksAreEnabled(spaceId);
    await t.gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));
    await t.navigateTo([
      TasksListPage.createNewTaskListKey,
    ]);

    await t.createTaskList(
      'Errands',
      description: 'These are the most important things to do',
      tasks: [
        'Buy milk',
        'Pickup dogs med',
      ],
    );

    await t.gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));
    await t.ensureHasWidget<SpaceHeader>();
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
      TasksListPage.createNewTaskListKey,
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
    await t.gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));
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
    await t.gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));
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
  acterTestWidget('Add many tasks scrolls fine', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      spaceDisplayName: 'Many Tasks',
    );
    await t.ensureTasksAreEnabled(spaceId);
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.createTaskListAction,
    ]);

    // the first one

    await t.createTaskList(
      'Club Party Groceries',
      description: 'Things we have to do buy for the party',
      tasks: [
        '4x packs cola',
        '3 bottles orange juice',
        '2 bottles apple juice',
        'card deck',
        'glitter',
        '4 packs of crisps',
        'bag of flips',
        'pretzels',
        'bananas',
        'apples',
        'bag of potatoes',
        'apple pie',
        'cheese cake',
        '50 plates',
        '10 forks',
        '50 cups',
      ],
      selectSpaceId: spaceId,
    );
  });

  acterTestWidget('Multiple TaskLists & tasks', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      spaceDisplayName: 'Multiple Tasks & Lists',
    );
    await t.ensureTasksAreEnabled(spaceId);
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.createTaskListAction,
    ]);

    // the first one

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
    await t.gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));
    // we see our entry now
    await find.text('Club Party').should(findsOneWidget);
    await find.text('Get drinks').should(findsOneWidget);
    await find.text('Order chips').should(findsOneWidget);
    await find.text('Remind everyone of the potluck').should(findsOneWidget);
    await t.navigateTo([
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      QuickJumpKeys.tasks,
    ]);
    // we see our entry now
    await find.text('Club Party').should(findsOneWidget);
    await find.text('Get drinks').should(findsOneWidget);
    await find.text('Order chips').should(findsOneWidget);
    await find.text('Remind everyone of the potluck').should(findsOneWidget);

    // the second one, created via the space itself.

    await t.gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));
    await t.navigateTo([
      TasksListPage.createNewTaskListKey,
    ]);

    await t.createTaskList(
      'Errands',
      description: 'These are the most important things to do',
      tasks: [
        'Buy milk',
        'Pickup dogs med',
      ],
    );

    await t.gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));
    await t.ensureHasWidget<SpaceHeader>();
    // we see our entry now

    final errands = find.text('Errands');

    await t.tester.ensureVisible(errands);
    await errands.should(findsOneWidget);
    await find.text('Buy milk').should(findsOneWidget);
    await find.text('Pickup dogs med').should(findsOneWidget);

    await t.navigateTo([
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      QuickJumpKeys.tasks,
    ]);
    // we see our entry now
    await find.text('Errands').should(findsOneWidget);
    await find.text('Buy milk').should(findsOneWidget);
    await find.text('Pickup dogs med').should(findsOneWidget);

    // and a third one

    await t.navigateTo([
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      QuickJumpKeys.tasks,
      TasksListPage.createNewTaskListKey,
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

    final protestPrep = find.text('Protest Preparations');

    await t.navigateTo([
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      QuickJumpKeys.tasks,
    ]);

    // scroll down to make the item visible
    await t.tester.scrollUntilVisible(protestPrep, 50);
    await find.text('Buy markers').should(findsOneWidget);
    await find.text('Pick up banner').should(findsOneWidget);

    //
    await t.gotoSpace(spaceId, appTab: Key(TabEntry.tasks.name));

    // we see our entry now
    await t.tester.dragUntilVisible(
      protestPrep,
      find.byKey(TasksListPage.scrollView),
      const Offset(0, -500),
    );
    await find.text('Buy markers').should(findsOneWidget);
    await find.text('Pick up banner').should(findsOneWidget);
  });

  acterTestWidget('Check and uncheck', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      spaceDisplayName: 'Protest Camp',
    );
    await t.ensureTasksAreEnabled(spaceId);
    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.createTaskListAction,
    ]);

    await t.createTaskList(
      'Kitchen',
      tasks: [
        'Refill sanitizer',
        'Buy soap',
      ],
      selectSpaceId: spaceId,
    );
    await t.navigateTo([MainNavKeys.quickJump, QuickJumpKeys.tasks]);
    // we see our entry now
    await find.text('Kitchen').should(findsOneWidget);
    await find.text('Buy soap').should(findsOneWidget);
    await find
        .text('Buy soap')
        .tap(); // this should navigate us to the item page

    // final btnNotDoneFinder = find.byKey(TaskInfo.statusBtnNotDone);
    // await btnNotDoneFinder.should(findsOneWidget);
    // await btnNotDoneFinder.tap(); // toggle done
    //
    // final btnDoneFinder = find.byKey(TaskInfo.statusBtnDone);
    // await btnDoneFinder.should(findsOneWidget);
    // await btnDoneFinder.tap(); // toggle undone

    // await btnNotDoneFinder.should(findsOneWidget); // is undone again
  });

  acterTestWidget('Create Tasks from overview', (t) async {
    final taskListId = (await t.freshWithTasks(
      [], // no tasks yet
      listTitle: 'Operations',
      spaceDisplayName: 'Protest Camp',
    ))
        .taskListId;

    await t.navigateTo([MainNavKeys.quickJump, QuickJumpKeys.tasks]);
    await find.text('Operations').should(findsOneWidget);

    final inlineAddBtn =
        find.byKey(Key('task-list-$taskListId-add-task-inline'));
    await inlineAddBtn.should(findsOneWidget);
    await inlineAddBtn.tap(); // activate inline add
    await t.addTasks(taskListId, ['Buy duct tape']);
    // close inline add
    final cancelInlineAdd =
        find.byKey(Key('task-list-$taskListId-add-task-inline-cancel'));
    await cancelInlineAdd.should(findsOneWidget);
    await cancelInlineAdd.tap();

    // we see our entry now
    await find.text('Operations').should(findsOneWidget);
    await find.text('Buy duct tape').should(findsOneWidget);
    final taskEntry = find
        .ancestor(
          of: find.text('Buy duct tape'),
          matching:
              find.byWidgetPredicate((Widget widget) => widget is TaskItem),
        )
        .evaluate()
        .first
        .widget as TaskItem;

    final btnNotDoneFinder = find.byKey(taskEntry.notDoneKey());
    await btnNotDoneFinder.should(findsOneWidget);
    await btnNotDoneFinder.tap(); // toggle done

    final btnDoneFinder = find.byKey(taskEntry.doneKey());
    await btnDoneFinder.should(findsOneWidget);
    await btnDoneFinder.tap(); // toggle undone

    await btnNotDoneFinder.should(findsOneWidget); // is undone again
  });

  acterTestWidget('Check and uncheck in overview', (t) async {
    await t.freshWithTasks(
      [
        'Refill sanitizer',
        'Buy duct tape',
      ],
      listTitle: 'Operations',
      spaceDisplayName: 'Protest Camp',
    );

    await t.navigateTo([MainNavKeys.quickJump, QuickJumpKeys.tasks]);
    // we see our entry now
    await find.text('Operations').should(findsOneWidget);
    await find.text('Buy duct tape').should(findsOneWidget);
    final taskEntry = find
        .ancestor(
          of: find.text('Buy duct tape'),
          matching:
              find.byWidgetPredicate((Widget widget) => widget is TaskItem),
        )
        .evaluate()
        .first
        .widget as TaskItem;

    final btnNotDoneFinder = find.byKey(taskEntry.notDoneKey());
    await btnNotDoneFinder.should(findsOneWidget);
    await btnNotDoneFinder.tap(); // toggle done

    final btnDoneFinder = find.byKey(taskEntry.doneKey());
    await btnDoneFinder.should(findsOneWidget);
    await btnDoneFinder.tap(); // toggle undone

    await btnNotDoneFinder.should(findsOneWidget); // is undone again
  });

  acterTestWidget('Change due date', (t) async {
    await t.freshWithTasks(
      [
        'Refill sanitizer',
        'Buy duct tape',
      ],
      listTitle: 'Operations',
      spaceDisplayName: 'Protest Camp',
    );

    // we see our entry now
    await find.text('Operations').should(findsOneWidget);
    await find.text('Buy duct tape').should(findsOneWidget);
    await find
        .text('Buy duct tape')
        .tap(); // this should navigate us to the item page

    // final dueDateFinder = find.byKey(TaskInfo.dueDateField);
    // await dueDateFinder.should(findsOneWidget);
    // await dueDateFinder.tap(); // open due dialog

    // // select tomorrow
    // final tomorrow = find.byKey(DuePicker.quickSelectTomorrow);
    // await tomorrow.should(findsOneWidget);
    // await tomorrow.tap(); // set to tomorrow
    //
    // await dueDateFinder.should(findsOneWidget);
    // // FIXME: translation problem
    // await find
    //     .descendant(of: dueDateFinder, matching: find.text('due tomorrow'))
    //     .should(findsOneWidget);
    //
    // await dueDateFinder.tap(); // open due dialog
    //
    // // select today
    // final today = find.byKey(DuePicker.quickSelectToday);
    // await today.should(findsOneWidget);
    // await today.tap(); // set to today
    //
    // await dueDateFinder.should(findsOneWidget);
    // await find
    //     .descendant(of: dueDateFinder, matching: find.text('due today'))
    //     .should(findsOneWidget);
    //
    // await t.navigateTo([MainNavKeys.quickJump, QuickJumpKeys.tasks]);
    // await find.text('Buy duct tape').should(findsOneWidget);
    //
    // final taskEntry = find.ancestor(
    //   of: find.text('Buy duct tape'),
    //   matching: find.byWidgetPredicate((Widget widget) => widget is TaskEntry),
    // );
    //
    // await find
    //     .descendant(of: taskEntry, matching: find.text('due today'))
    //     .should(findsOneWidget);
  });

  acterTestWidget('Change title', (t) async {
    await t.freshWithTasks(
      [
        'Buy duct tape',
      ],
      listTitle: 'Operations',
      spaceDisplayName: 'Protest Camp',
    );

    // we see our entry now
    await find.text('Operations').should(findsOneWidget);
    await find.text('Buy duct tape').should(findsOneWidget);
    await find
        .text('Buy duct tape')
        .tap(); // this should navigate us to the item page
    await t.renameTask('Buy black gaffer tape');
    await find.text('Buy black gaffer tape').should(findsOneWidget);
  });

  acterTestWidget('Change body', (t) async {
    await t.freshWithTasks(
      [
        'Refill sanitizer',
      ],
      listTitle: 'Operations',
      spaceDisplayName: 'Protest Camp',
    );

    // we see our entry now
    await find.text('Operations').should(findsOneWidget);
    await find.text('Refill sanitizer').should(findsOneWidget);
    await find
        .text('Refill sanitizer')
        .tap(); // this should navigate us to the item page

    await t.replaceTaskBody('At least 6 packages of 500ml or more');
    await find
        .text('At least 6 packages of 500ml or more')
        .should(findsOneWidget);

    await t.replaceTaskBody('At least 10 packages of 500ml or more');

    await find
        .text('At least 10 packages of 500ml or more')
        .should(findsOneWidget);
  });

  acterTestWidget('Self Assignment ', (t) async {
    await t.freshWithTasks(
      [
        'Take out the trash',
      ],
      listTitle: 'Cleaning',
      spaceDisplayName: 'Club House',
      userDisplayName: 'Ruben',
    );

    // we see our entry now
    await find.text('Cleaning').should(findsOneWidget);
    await find.text('Take out the trash').should(findsOneWidget);
    await find
        .text('Take out the trash')
        .tap(); // this should navigate us to the item page

    // ensure we are not assigned
    // final assignmentsField = find.byKey(TaskInfo.assignmentsFields);
    // await assignmentsField.should(findsOneWidget);
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Ruben'))
    //     .should(findsNothing);
    //
    // final selfAssign = find.byKey(TaskInfo.selfAssignKey);
    // await selfAssign.should(findsOneWidget);
    // await selfAssign.tap(); // assign myself
    //
    // // FOUND!
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Ruben'))
    //     .should(findsOneWidget);
    // await selfAssign.should(findsNothing); // and the button is gone
    //
    // // but the unassign button is there.
    // final selfUnassign = find.byKey(TaskInfo.selfUnassignKey);
    // await selfUnassign.should(findsOneWidget);
    // await selfUnassign.tap(); // unassign myself

    // and we are not assigned anymore \o/
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Ruben'))
    //     .should(findsNothing);
    //
    // // let's assign ourselves again.
    // await selfAssign.should(findsOneWidget);
    // await selfAssign.tap(); // assign myself
    //
    // // FOUND!
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Ruben'))
    //     .should(findsOneWidget);
    // await selfAssign.should(findsNothing); // and the button is gone

    // okay, this should show up on our dashboard now!
    await t.navigateTo([
      MainNavKeys.dashboardHome,
      MainNavKeys.dashboardHome,
    ]);

    await find
        .text('Take out the trash')
        .should(findsOneWidget); // this should navigate us to the item page

    final taskEntry = find
        .ancestor(
          of: find.text('Take out the trash'),
          matching:
              find.byWidgetPredicate((Widget widget) => widget is TaskItem),
        )
        .evaluate()
        .first
        .widget as TaskItem;

    // mark as done.
    final btnNotDoneFinder = find.byKey(taskEntry.notDoneKey());
    await btnNotDoneFinder.should(findsOneWidget);
    await btnNotDoneFinder.tap(); // toggle done

    // makes it disappear!
    await find.text('Take out the trash').should(findsNothing);
  });

  acterTestWidget('Full multi user run', (t) async {
    // final spaceId = (await t.freshWithTasks(
    //   [
    //     'Trash',
    //   ],
    //   listTitle: 'Cleaning',
    //   spaceDisplayName: 'Club House',
    //   userDisplayName: 'Alice',
    // ))
    //     .spaceId;

    // we see our entry now
    await find.text('Cleaning').should(findsOneWidget);
    await find.text('Trash').should(findsOneWidget);
    await find.text('Trash').tap(); // this should navigate us to the item page

    // assignment

    // ensure we are not assigned
    // final assignmentsField = find.byKey(TaskInfo.assignmentsFields);
    // await assignmentsField.should(findsOneWidget);
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Alice'))
    //     .should(findsNothing);
    //
    // final selfAssign = find.byKey(TaskInfo.selfAssignKey);
    // await selfAssign.should(findsOneWidget);
    // await selfAssign.tap(); // assign myself
    //
    // // FOUND!
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Alice'))
    //     .should(findsOneWidget);
    // await selfAssign.should(findsNothing); // and the button is gone
    //
    // // but the unassign button is there.
    // final selfUnassign = find.byKey(TaskInfo.selfUnassignKey);
    // await selfUnassign.should(findsOneWidget);
    // await selfUnassign.tap(); // unassign myself
    //
    // // and we are not assigned anymore \o/
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Alice'))
    //     .should(findsNothing);
    //
    // // -- change body
    //
    // await t.replaceTaskBody(
    //   'Both the one in the kitchen and the one in the bathroom',
    // );
    // await find
    //     .text('Both the one in the kitchen and the one in the bathroom')
    //     .should(findsOneWidget);
    //
    // // -- change title
    // await t.renameTask('Take out the trash');
    // await find.text('Take out the trash').should(findsOneWidget);
    //
    // // -- change due
    //
    // final dueDateFinder = find.byKey(TaskInfo.dueDateField);
    // await dueDateFinder.should(findsOneWidget);
    // await dueDateFinder.tap(); // open due dialog

    // select today
    // final today = find.byKey(DuePicker.quickSelectToday);
    // await today.should(findsOneWidget);
    // await today.tap(); // set to today
    //
    // await dueDateFinder.should(findsOneWidget);
    // await find
    //     .descendant(of: dueDateFinder, matching: find.text('due today'))
    //     .should(findsOneWidget);
    //
    // // okay, let's get that other person in.
    // final tokenCode = await t.createSuperInvite([spaceId]);
    //
    // await t.logout();
    // await t.freshAccount(registrationToken: tokenCode, displayName: 'Bahira');
    // await t.ensureTasksAreEnabled(null);
    //
    // await t.navigateTo([
    //   MainNavKeys.quickJump,
    //   QuickJumpKeys.tasks,
    // ]);
    //
    // await find.text('Cleaning').should(findsOneWidget);
    // await find.text('Take out the trash').should(findsOneWidget);
    // await find
    //     .text('Take out the trash')
    //     .tap(); // this should navigate us to the item page
    //
    // // -- check values and content:
    // await dueDateFinder.should(findsOneWidget);
    // await find
    //     .descendant(of: dueDateFinder, matching: find.text('due today'))
    //     .should(findsOneWidget);
    // await find
    //     .text('Both the one in the kitchen and the one in the bathroom')
    //     .should(findsOneWidget);
    //
    // // ensure Alice isn't assigned
    // await assignmentsField.should(findsOneWidget);
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Alice'))
    //     .should(findsNothing);
    //
    // await selfAssign.should(findsOneWidget);
    // await selfAssign.tap(); // assign myself
    //
    // // we are now assigned
    // await find
    //     .descendant(of: assignmentsField, matching: find.text('Bahira'))
    //     .should(findsOneWidget);
    // await selfAssign.should(findsNothing); // and the button is gone
    //
    // // and the unassign button is there.
    // await selfUnassign.should(findsOneWidget);
    //
    // // okay, this should show up on our dashboard now!
    // await t.navigateTo([
    //   MainNavKeys.dashboardHome,
    //   MainNavKeys.dashboardHome,
    // ]);
    //
    // await find
    //     .text('Take out the trash')
    //     .should(findsOneWidget); // this should navigate us to the item page
    //
    // final taskEntry = find
    //     .ancestor(
    //       of: find.text('Take out the trash'),
    //       matching:
    //           find.byWidgetPredicate((Widget widget) => widget is TaskEntry),
    //     )
    //     .evaluate()
    //     .first
    //     .widget as TaskEntry;

    // mark as done.
    // final btnNotDoneFinder = find.byKey(taskEntry.notDoneKey());
    // await btnNotDoneFinder.should(findsOneWidget);
    // await btnNotDoneFinder.tap(); // toggle done
    //
    // // makes it disappear!
    // await find.text('Take out the trash').should(findsNothing);
  });
}
