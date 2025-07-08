import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/tasks/widgets/task_invitations_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/providers/common_providers.dart';
import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_tasks_providers.dart';
import '../../../helpers/test_util.dart';

class MockAsyncTaskHasInvitationsNotifier extends AsyncTaskHasInvitationsNotifier {
  @override
  Future<bool> build(Task task) async => (task as MockTask).hasInvitations;
}

class MockAsyncTaskInvitationsNotifier extends AsyncTaskInvitationsNotifier {
  @override
  Future<List<String>> build(Task task) async => (task as MockTask).invitedUsers;
}

void main() {
  late MockTask mockTask;
  late BuildContext context;

  setUpAll(() {
    registerFallbackValue(MockEventId(id: 'event123'));
  });

  setUp(() {
    mockTask = MockTask();
  });

  Future<void> pumpTaskInvitationsWidget(WidgetTester tester, MockTask mockTask) async {
    await tester.pumpProviderWidget(
      child: TaskInvitationsWidget(task: mockTask),
      overrides: [
        taskHasInvitationsProvider.overrideWith(
          () => MockAsyncTaskHasInvitationsNotifier(),
        ),
        taskInvitationsProvider.overrideWith(
          () => MockAsyncTaskInvitationsNotifier(),
        ),
        myUserIdStrProvider.overrideWithValue('current_user'),
      ],
    );
    await tester.pump();
    context = tester.element(find.byType(TaskInvitationsWidget));
  }

  group('TaskInvitationsWidget', () {
    testWidgets('does not display when no invitations', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        hasInvitations: false,
        invitedUsers: [],
      );

      await pumpTaskInvitationsWidget(tester, mockTask);

      expect(find.byType(TaskInvitationsWidget), findsOneWidget);
      expect(find.text(L10n.of(context).invited), findsNothing);
    });

    testWidgets('displays invitations when task has invitations', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        hasInvitations: true,
        invitedUsers: ['user1', 'user2'],
      );

      await pumpTaskInvitationsWidget(tester, mockTask);
      await tester.pumpAndSettle();

      expect(find.text(L10n.of(context).invited), findsOneWidget);
      expect(find.byIcon(PhosphorIconsLight.userCheck), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(UserChip), findsNWidgets(2));
    });

    testWidgets('displays user chips with correct display names', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        hasInvitations: true,
        invitedUsers: ['user1'],
      );

      await pumpTaskInvitationsWidget(tester, mockTask);
      await tester.pumpAndSettle();

      expect(find.byType(UserChip), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('user1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays multiple user chips for multiple invitations', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        hasInvitations: true,
        invitedUsers: ['user1', 'user2', 'user3'],
      );

      await pumpTaskInvitationsWidget(tester, mockTask);
      await tester.pumpAndSettle();

      expect(find.byType(UserChip), findsNWidgets(3));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('user1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('user2'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('user3'),
        ),
        findsOneWidget,
      );
    });
  });
} 