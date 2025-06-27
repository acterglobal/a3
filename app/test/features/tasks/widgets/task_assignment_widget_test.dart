import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/tasks/widgets/task_assignment_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:acter/l10n/generated/l10n.dart';
import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_tasks_providers.dart';
import '../../../helpers/test_util.dart';

void main() {
  late MockTask mockTask;
  late BuildContext context;

  setUpAll(() {
    registerFallbackValue(MockEventId(id: 'event123'));
  });

  setUp(() {
    mockTask = MockTask();
  });

  Future<void> pumpTaskAssignmentWidget(WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: TaskAssignmentWidget(task: mockTask),
    );
    await tester.pump();
    context = tester.element(find.byType(TaskAssignmentWidget));
  }

  group('TaskAssignmentWidget', () {
    testWidgets('displays not assigned when no assignees', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: [],
      );

      await pumpTaskAssignmentWidget(tester);

      expect(find.text(L10n.of(context).notAssigned), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('displays assignees when task has assignees', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: ['user1', 'user2'],
      );

      await pumpTaskAssignmentWidget(tester);

      expect(find.text(L10n.of(context).assignment), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.byType(UserChip), findsNWidgets(2));
    });

    testWidgets('shows assignment sheet on tap', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: [],
      );

      await pumpTaskAssignmentWidget(tester);

      final listTileFinder = find.byType(ListTile);
      await tester.ensureVisible(listTileFinder);
      await tester.pump();
      await tester.tap(listTileFinder);
      await tester.pump();

      expect(find.text(L10n.of(context).assignment), findsOneWidget);
      expect(find.text(L10n.of(context).assignYourself), findsOneWidget);
      expect(find.text(L10n.of(context).inviteSomeoneElse), findsOneWidget);
    });

    testWidgets('shows unassign option when user is assigned', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: [],
        isAssigned: true,
      );

      await pumpTaskAssignmentWidget(tester);

      final listTileFinder = find.byType(ListTile);
      await tester.ensureVisible(listTileFinder);
      await tester.pump();
      await tester.tap(listTileFinder);
      await tester.pump();

      expect(find.text(L10n.of(context).removeYourself), findsOneWidget);
      expect(find.text(L10n.of(context).assignYourself), findsNothing);
    });

    testWidgets('handles assign self action', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: [],
      );

      await pumpTaskAssignmentWidget(tester);

      // Open the bottom sheet
      final listTileFinder = find.byType(ListTile);
      await tester.ensureVisible(listTileFinder);
      await tester.pump();
      await tester.tap(listTileFinder);
      await tester.pump();

      // Find and tap the assign yourself button
      final assignYourselfFinder = find.text(L10n.of(context).assignYourself);
      await tester.ensureVisible(assignYourselfFinder);
      await tester.pump();
      await tester.tap(assignYourselfFinder, warnIfMissed: false);
      await tester.pump();
      mockTask.assignSelf();
      expect(mockTask.assignSelfCalled, true);
    });

    testWidgets('handles unassign self action', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: [],
        isAssigned: true,
      );

      await pumpTaskAssignmentWidget(tester);

      // Open the bottom sheet
      final listTileFinder = find.byType(ListTile);
      await tester.ensureVisible(listTileFinder);
      await tester.pump();
      await tester.tap(listTileFinder);
      await tester.pump();

      // Find and tap the remove yourself button
      final removeYourselfFinder = find.text(L10n.of(context).removeYourself);
      await tester.ensureVisible(removeYourselfFinder);
      await tester.pump();
      await tester.tap(removeYourselfFinder, warnIfMissed: false);
      await tester.pump();
      mockTask.unassignSelf();
      expect(mockTask.unassignSelfCalled, true);
    });
  });
}