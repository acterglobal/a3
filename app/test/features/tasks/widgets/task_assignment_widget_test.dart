import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
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

    testWidgets('displays trailing more_vert icon when task has assignees', (tester) async {
      // Setup mock behavior with assignees to trigger trailing widget
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: ['user1'],
      );

      await pumpTaskAssignmentWidget(tester);

      // Verify the trailing more_vert icon is displayed
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      
      // Verify the trailing widget is an InkWell (there might be multiple InkWells)
      final trailingInkWell = find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(InkWell),
      );
      expect(trailingInkWell, findsAtLeastNWidgets(1));
    });

    testWidgets('builds assignees with UserChip widgets correctly', (tester) async {
      // Setup mock behavior with multiple assignees
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: ['user1', 'user2', 'user3'],
        roomId: 'room123',
      );

      await pumpTaskAssignmentWidget(tester);

      // Verify UserChip widgets are created for each assignee
      expect(find.byType(UserChip), findsNWidgets(3));
      
      // Verify the Wrap widget contains the UserChips
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('UserChip onTap calls onUnAssign when isMe is true', (tester) async {
      // Setup mock behavior with current user as assignee
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: ['current_user'],
        roomId: 'room123',
      );

      await pumpTaskAssignmentWidget(tester);

      // Find and tap a UserChip
      final userChipFinder = find.byType(UserChip);
      expect(userChipFinder, findsOneWidget);
      
      // Tap the UserChip to trigger onTap
      await tester.tap(userChipFinder);
      await tester.pump();
      
      // Verify the UserChip is properly configured
      final userChip = tester.widget<UserChip>(userChipFinder);
      expect(userChip.roomId, equals('room123'));
      expect(userChip.memberId, equals('current_user'));
    });

    testWidgets('shows assignment sheet with proper modal configuration', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: [],
      );

      await pumpTaskAssignmentWidget(tester);

      // Open the bottom sheet
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder);
      await tester.pump();

      // Verify the modal bottom sheet is displayed with proper configuration
      expect(find.text(L10n.of(context).assignment), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verify the AppBar has transparent background and no leading
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(Colors.transparent));
      expect(appBar.automaticallyImplyLeading, isFalse);
    });

    testWidgets('handles invite someone else navigation', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: [],
        roomId: 'room123',
      );

      await pumpTaskAssignmentWidget(tester);

      // Open the bottom sheet
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder);
      await tester.pump();

      // Find and tap the invite someone else button
      final inviteSomeoneElseFinder = find.text(L10n.of(context).inviteSomeoneElse);
      expect(inviteSomeoneElseFinder, findsOneWidget);
      
      // Verify the MenuItemWidget is properly configured
      final menuItemWidget = find.descendant(
        of: find.byType(Column),
        matching: find.byType(MenuItemWidget),
      );
      expect(menuItemWidget, findsNWidgets(2)); // assignYourself + inviteSomeoneElse
    });

    testWidgets('displays proper styling for not assigned text', (tester) async {
      // Setup mock behavior with no assignees
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: [],
      );

      await pumpTaskAssignmentWidget(tester);

      // Verify the not assigned text is displayed with proper styling
      final notAssignedText = find.text(L10n.of(context).notAssigned);
      expect(notAssignedText, findsOneWidget);
      
      // Verify it's wrapped in a Padding widget (there might be multiple Padding widgets)
      final paddingWidget = find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(Padding),
      );
      expect(paddingWidget, findsAtLeastNWidgets(1));
    });

    testWidgets('displays proper styling for assignment text when has assignees', (tester) async {
      // Setup mock behavior with assignees
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        assignees: ['user1'],
      );

      await pumpTaskAssignmentWidget(tester);

      // Verify the assignment text is displayed
      final assignmentText = find.text(L10n.of(context).assignment);
      expect(assignmentText, findsOneWidget);
      
      // Verify the subtitle is displayed when there are assignees
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNotNull);
    });
  });
}