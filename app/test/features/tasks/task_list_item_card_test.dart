import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../../helpers/test_util.dart';

class MockOnTapTaskItem extends Mock {
  void call(String taskId);
}

void main() {
  late FakeTaskList mockTask;
  late MockOnTapTaskItem mockOnTapTaskItem;

  setUp(() {
    mockTask = FakeTaskList();
    mockOnTapTaskItem = MockOnTapTaskItem();
  });

  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    bool isShowTaskListIndication = false,
    bool isShowSpaceName = false,
    bool isShowOnlyTaskList = false,
    bool isShowCompletedTask = false,
    bool initiallyExpanded = true,
    bool canExpand = true,
    GestureTapCallback? onTitleTap,
  }) async {
    final mockedNotifier = FakeTaskListItemNotifier(shouldFail: false);

    await tester.pumpProviderWidget(
      overrides: [
        taskListProvider.overrideWith(() => mockedNotifier),
        roomDisplayNameProvider.overrideWith((a, b) => 'space name'),
      ],
      child: TaskListItemCard(
        taskListId: mockTask.eventId,
        showSpace: isShowSpaceName,
        showTaskListIndication: isShowTaskListIndication,
        showCompletedTask: isShowCompletedTask,
        showOnlyTaskList: isShowOnlyTaskList,
        initiallyExpanded: initiallyExpanded,
        canExpand: canExpand,
        onTitleTap: onTitleTap,
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
  }

  testWidgets('TaskListItemCard expands when canExpand is true', (
    tester,
  ) async {
    // Setup
    await createWidgetUnderTest(tester: tester);

    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(
      find.byType(TaskItemsListWidget),
      findsOneWidget,
    ); // Expect that TaskItemsListWidget is shown when expandable
  });

  testWidgets('TaskListItemCard shows ListTile when canExpand is false', (
    tester,
  ) async {
    // Setup
    await createWidgetUnderTest(tester: tester, canExpand: false);

    expect(find.byType(ListTile), findsOneWidget);
    expect(
      find.byType(TaskItemsListWidget),
      findsNothing,
    ); // TaskItemsListWidget should not be shown
  });
  testWidgets(
    'TaskListItemCard shows task list indication when showTaskListIndication is true',
    (tester) async {
      // Setup
      await createWidgetUnderTest(
        tester: tester,
        isShowTaskListIndication: true,
      );
      expect(
        find.byIcon(Atlas.list),
        findsOneWidget,
      ); // Expect the list icon to be present
      expect(
        find.text('Task List'),
        findsOneWidget,
      ); // Expect task list indication text
    },
  );
  testWidgets(
    'TaskListItemCard shows no task items when showOnlyTaskList is true',
    (tester) async {
      // Setup
      await createWidgetUnderTest(tester: tester, isShowOnlyTaskList: true);
      expect(find.byType(TaskItemsListWidget), findsNothing);
    },
  );
  testWidgets('TaskListItemCard shows space chip when showSpace is true', (
    tester,
  ) async {
    await createWidgetUnderTest(tester: tester, isShowSpaceName: true);
    expect(find.text('space name'), findsOneWidget);
  });
  testWidgets(
    'TaskListItemCard navigates to task list details when title is tapped',
    (tester) async {
      // Setup: Provide a mock callback for title tap
      await createWidgetUnderTest(
        tester: tester,
        onTitleTap: () {
          mockOnTapTaskItem.call(mockTask.eventId);
        },
      );
      await tester.tap(find.byKey(Key('task-list-title-${mockTask.eventId}')));
    },
  );

  testWidgets(
    'TaskListItemCard does not show task items when showOnlyTaskList is true',
    (tester) async {
      // Setup: Ensure showOnlyTaskList is true to hide task items
      await createWidgetUnderTest(tester: tester, isShowOnlyTaskList: true);
      expect(find.byType(TaskItemsListWidget), findsNothing);
    },
  );

  testWidgets(
    'TaskListItemCard shows task items when showOnlyTaskList is false',
    (tester) async {
      // Setup: Ensure showOnlyTaskList is false to show task items
      await createWidgetUnderTest(tester: tester);
      expect(find.byType(TaskItemsListWidget), findsOneWidget);
    },
  );

  testWidgets('TaskListItemCard uses correct icon', (tester) async {
    // Setup: Create the widget and check the icon
    await createWidgetUnderTest(tester: tester);
    expect(find.byType(ActerIconWidget), findsOneWidget);
  });
}
