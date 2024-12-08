import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/tasks/actions/create_task.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';

import '../../helpers/mock_a3sdk.dart';
import '../../helpers/mock_go_router.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../../helpers/test_util.dart';

class FakeBottomModal<T> extends Fake implements ModalBottomSheetRoute<T> {}

void main() {
  group('Create Task Widget on TaskList', () {
    late MockGoRouter mockedGoRouter;
    late MockNavigator navigator;

    setUpAll(() {
      registerFallbackValue(FakeBottomModal<PickedDue>());
    });

    setUp(() {
      mockedGoRouter = MockGoRouter();
      navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(() => navigator.pop(any())).thenAnswer((_) async {});
      when(() => navigator.push<void>(any())).thenAnswer((_) async {});
    });

    testWidgets('Simple only title', (tester) async {
      final mockTaskList = MockTaskList();
      final mockTaskDraft = MockTaskDraft();
      when(() => mockTaskList.taskBuilder()).thenAnswer((_) => mockTaskDraft);
      when(() => mockTaskDraft.title('My new Task')).thenAnswer((_) => true);
      when(() => mockTaskDraft.send())
          .thenAnswer((_) async => MockEventId(id: 'test'));

      await tester.pumpProviderWidget(
        navigatorOverride: navigator,
        goRouter: mockedGoRouter,
        overrides: [
          selectedSpaceDetailsProvider.overrideWith((_) => null),
        ],
        child: CreateTaskWidget(
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
    testWidgets('with description', (tester) async {
      final mockTaskList = MockTaskList();
      final mockTaskDraft = MockTaskDraft();
      when(() => mockTaskList.taskBuilder()).thenAnswer((_) => mockTaskDraft);
      when(() => mockTaskDraft.title(any())).thenAnswer((_) => true);
      when(() => mockTaskDraft.descriptionText(any())).thenAnswer((_) => true);
      when(() => mockTaskDraft.send())
          .thenAnswer((_) async => MockEventId(id: 'test'));
      await tester.pumpProviderWidget(
        navigatorOverride: navigator,
        goRouter: mockedGoRouter,
        overrides: [
          selectedSpaceDetailsProvider.overrideWith((_) => null),
        ],
        child: CreateTaskWidget(
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
      await tester.enterText(title, 'Task with Description');

      // add due date

      final addDescAction = find.byKey(CreateTaskWidget.addDescAction);
      final descField = find.byKey(CreateTaskWidget.descField);

      // not yet visible
      expect(descField, findsNothing);

      expect(addDescAction, findsOneWidget);
      await tester.tap(addDescAction);
      await tester.pump();

      // now visible
      expect(descField, findsOneWidget);

      await tester.enterText(descField, 'This is the description');

      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);

      verify(() => mockTaskList.taskBuilder()).called(1);
      verify(() => mockTaskDraft.title('Task with Description')).called(1);
      verify(
        () => mockTaskDraft.descriptionText('This is the description'),
      ).called(1);
      verify(() => mockTaskDraft.send()).called(1);
      verifyNever(() => mockTaskDraft.dueDate(any(), any(), any()));
    });

    testWidgets('toggle description, not added', (tester) async {
      final mockTaskList = MockTaskList();
      final mockTaskDraft = MockTaskDraft();
      when(() => mockTaskList.taskBuilder()).thenAnswer((_) => mockTaskDraft);
      when(() => mockTaskDraft.title(any())).thenAnswer((_) => true);
      when(() => mockTaskDraft.descriptionText(any())).thenAnswer((_) => true);
      when(() => mockTaskDraft.send())
          .thenAnswer((_) async => MockEventId(id: 'test'));
      await tester.pumpProviderWidget(
        navigatorOverride: navigator,
        goRouter: mockedGoRouter,
        overrides: [
          selectedSpaceDetailsProvider.overrideWith((_) => null),
        ],
        child: CreateTaskWidget(
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
      await tester.enterText(title, 'Task with Description');

      // add due date

      final addDescAction = find.byKey(CreateTaskWidget.addDescAction);
      final descField = find.byKey(CreateTaskWidget.descField);

      // not yet visible
      expect(descField, findsNothing);

      expect(addDescAction, findsOneWidget);
      await tester.tap(addDescAction);
      await tester.pump();

      // now visible
      expect(descField, findsOneWidget);

      await tester.enterText(descField, 'This is the description');

      // but we decided against it again after
      final closeDescAction = find.byKey(CreateTaskWidget.closeDescAction);
      expect(closeDescAction, findsOneWidget);
      await tester.tap(closeDescAction);

      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);

      verify(() => mockTaskList.taskBuilder()).called(1);
      verify(() => mockTaskDraft.title('Task with Description')).called(1);
      verify(() => mockTaskDraft.send()).called(1);

      verifyNever(
        () => mockTaskDraft.descriptionText('This is the description'),
      );
      verifyNever(() => mockTaskDraft.dueDate(any(), any(), any()));
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

      when(() => navigator.push<PickedDue>(any()))
          .thenAnswer((_) async => Future.value(null));
      await tester.pumpProviderWidget(
        navigatorOverride: navigator,
        goRouter: mockedGoRouter,
        overrides: [
          selectedSpaceDetailsProvider.overrideWith((_) => null),
        ],
        child: CreateTaskWidget(
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

      // it was called!
      verify(() => navigator.push<PickedDue>(any())).called(1);

      // now visible
      expect(dueDateField, findsOneWidget);
      expect(dueTomorrow, findsOneWidget);

      await tester.ensureVisible(dueTomorrow);
      await tester.tap(dueTomorrow);
      await tester.pump();

      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

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

    testWidgets('with due date toggled, not added', (tester) async {
      final mockTaskList = MockTaskList();
      final mockTaskDraft = MockTaskDraft();
      when(() => mockTaskList.taskBuilder()).thenAnswer((_) => mockTaskDraft);
      when(() => mockTaskDraft.title('My new Task')).thenAnswer((_) => true);
      when(() => mockTaskDraft.dueDate(any(), any(), any()))
          .thenAnswer((_) => true);
      when(() => mockTaskDraft.send())
          .thenAnswer((_) async => MockEventId(id: 'test'));

      when(() => navigator.push<PickedDue>(any()))
          .thenAnswer((_) async => Future.value(null));

      await tester.pumpProviderWidget(
        navigatorOverride: navigator,
        goRouter: mockedGoRouter,
        overrides: [
          selectedSpaceDetailsProvider.overrideWith((_) => null),
        ],
        child: CreateTaskWidget(
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

      // it was called!
      verify(() => navigator.push<PickedDue>(any())).called(1);

      // now visible
      expect(dueDateField, findsOneWidget);
      expect(dueTomorrow, findsOneWidget);

      await tester.tap(dueTomorrow);

      // we closed the due again
      final closeDueDateAction =
          find.byKey(CreateTaskWidget.closeDueDateAction);
      expect(closeDueDateAction, findsOneWidget);
      await tester.tap(closeDueDateAction);

      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);

      final expectedDate = DateTime.now().add(const Duration(days: 1));

      verify(() => mockTaskList.taskBuilder()).called(1);
      verify(() => mockTaskDraft.title('Another Task')).called(1);
      verifyNever(
        () => mockTaskDraft.dueDate(
          expectedDate.year,
          expectedDate.month,
          expectedDate.day,
        ),
      );
      verify(() => mockTaskDraft.send()).called(1);
    });

    testWidgets('with due date from immediate dialog', (tester) async {
      final mockTaskList = MockTaskList();
      final mockTaskDraft = MockTaskDraft();
      when(() => mockTaskList.taskBuilder()).thenAnswer((_) => mockTaskDraft);
      when(() => mockTaskDraft.title('My new Task')).thenAnswer((_) => true);
      when(() => mockTaskDraft.dueDate(any(), any(), any()))
          .thenAnswer((_) => true);
      when(() => mockTaskDraft.send())
          .thenAnswer((_) async => MockEventId(id: 'test'));

      final expectedDate = DateTime.now().add(const Duration(days: 1));

      when(() => navigator.push<PickedDue>(any())).thenAnswer(
        (_) async => Future.value(
          PickedDue(expectedDate, false), // we directly return a selected date
        ),
      );
      await tester.pumpProviderWidget(
        navigatorOverride: navigator,
        goRouter: mockedGoRouter,
        overrides: [
          selectedSpaceDetailsProvider.overrideWith((_) => null),
        ],
        child: CreateTaskWidget(
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

      expect(addDueDateAction, findsOneWidget);
      await tester.tap(addDueDateAction);
      await tester.pump();

      // it was called!
      verify(() => navigator.push<PickedDue>(any())).called(1);

      // and we are not trying anything else

      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

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

  group('Create Task no Tasklist', () {
    testWidgets('Simple only title no tasklist', (tester) async {
      final mockTaskList = MockTaskList();
      final mockTaskDraft = MockTaskDraft();
      when(() => mockTaskList.taskBuilder()).thenAnswer((_) => mockTaskDraft);
      when(() => mockTaskDraft.title('My new Task')).thenAnswer((_) => true);
      when(() => mockTaskDraft.send())
          .thenAnswer((_) async => MockEventId(id: 'test'));
      await tester.pumpProviderWidget(
        overrides: [
          selectedSpaceDetailsProvider.overrideWith((_) => null),
        ],
        child: const CreateTaskWidget(),
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

      // blocks because we have no task list yet
      verifyNever(() => mockTaskList.taskBuilder());
    });
  });
}
