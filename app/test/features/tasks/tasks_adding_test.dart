import 'package:acter/features/tasks/sheets/create_update_task_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_a3sdk.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Create Task Widget', () {
    testWidgets('Simple only title', (tester) async {
      final mockTaskList = MockTaskList();
      final mockTaskDraft = MockTaskDraft();
      when(() => mockTaskList.taskBuilder()).thenAnswer((_) => mockTaskDraft);
      when(() => mockTaskDraft.title('My new Task')).thenAnswer((_) => true);
      when(() => mockTaskDraft.send())
          .thenAnswer((_) async => MockEventId(id: 'test'));
      await tester.pumpProviderWidget(
        overrides: [],
        child: CreateTaskWidget(
          taskName: '',
          taskList: mockTaskList,
        ),
      );
      // try to submit without a title

      final submitBtn = find.byKey(CreateTaskWidget.submitBtn);
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);

      // not called
      verifyNever(() => mockTaskList.taskBuilder());

      // add the title

      final title = find.byKey(CreateTaskWidget.titleField);
      expect(title, findsOneWidget);
      await tester.enterText(title, 'My new Task');

      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);

      verify(() => mockTaskList.taskBuilder()).called(1);
      verify(() => mockTaskDraft.title('My new Task')).called(1);
      verify(() => mockTaskDraft.send()).called(1);
    });
    testWidgets('with due date', (tester) async {
      final mockTaskList = MockTaskList();
      final mockTaskDraft = MockTaskDraft();
      when(() => mockTaskList.taskBuilder()).thenAnswer((_) => mockTaskDraft);
      when(() => mockTaskDraft.title('My new Task')).thenAnswer((_) => true);
      when(() => mockTaskDraft.dueDate(any(), any(), any()))
          .thenAnswer((_) => true);
      when(() => mockTaskDraft.send())
          .thenAnswer((_) async => MockEventId(id: 'test'));
      await tester.pumpProviderWidget(
        overrides: [],
        child: CreateTaskWidget(
          taskName: '',
          taskList: mockTaskList,
        ),
      );
      // try to submit without a title

      final submitBtn = find.byKey(CreateTaskWidget.submitBtn);
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);

      // not called
      verifyNever(() => mockTaskList.taskBuilder());

      // add the title
      final title = find.byKey(CreateTaskWidget.titleField);
      expect(title, findsOneWidget);
      await tester.enterText(title, 'Another Task');

      // add due date

      final addDueDateAction = find.byKey(CreateTaskWidget.addDueDateAction);
      final dueDateField = find.byKey(CreateTaskWidget.dueDateField);
      final dueTomorrow = find.byKey(CreateTaskWidget.dueDateTomorrowBtn);

      // not yet visible
      expect(dueDateField, findsNothing);
      expect(dueTomorrow, findsNothing);

      expect(addDueDateAction, findsOneWidget);
      await tester.tap(addDueDateAction);
      await tester.pump();

      // now visible
      expect(dueDateField, findsOneWidget);
      expect(dueTomorrow, findsOneWidget);

      await tester.tap(dueTomorrow);

      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);

      final expectedDate = DateTime.now().add(const Duration(days: 1));

      verify(() => mockTaskList.taskBuilder()).called(1);
      verify(() => mockTaskDraft.title('Another Task')).called(1);
      verify(
        () => mockTaskDraft.dueDate(
          expectedDate.year,
          expectedDate.month,
          expectedDate.day,
        ),
      ).called(1);
      verify(() => mockTaskDraft.send()).called(1);
    });
  });
}
