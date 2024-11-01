import 'package:acter/features/tasks/sheets/create_update_task_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_a3sdk.dart';
import '../../helpers/mock_tasks_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Adding Task Widget', () {
    testWidgets('Create task', (tester) async {
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
  });
}
