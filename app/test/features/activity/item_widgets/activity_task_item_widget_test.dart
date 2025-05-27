import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskAccepted.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskAdd.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskComplete.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskDecline.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskDueDateChange.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/taskReOpen.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/test_util.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_activity_object.dart';
import '../mock_data/mock_date_change.dart';

void main() {
  testWidgets('task added on task list', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockName: 'task 1',
      mockSubType: 'Task',
      mockType: PushStyles.taskAdd.name,
      mockObject: MockActivityObject(
        mockType: 'task-list',
        mockEmoji: '📋',
        mockTitle: 'Project Task List',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(child: ActivityTaskAddItemWidget(activity: mockActivity)),
    );
    // Wait for the async provider to load
    await tester.pumpAndSettle();

    // Verify action icon
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

    // Verify action title
    expect(find.text('Added task on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.listChecks), findsAtLeast(1));

    // Verify object info
    expect(find.text('Project Task List'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify task content
    expect(find.text('Task : task 1'), findsOneWidget);
  });

  testWidgets('Date changed on Task Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.taskDueDateChange.name,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockEmoji: '☑️',
        mockTitle: 'Project Task',
      ),
      mockDateContent: MockDateContent(
        mockChange: 'Changed',
        mockNewVal: '2024-03-09',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityTaskDueDateChangedItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pumpAndSettle();

    // Verify action icon
    expect(find.byIcon(Icons.access_time), findsOneWidget);

    // Verify action title
    expect(find.text('Rescheduled'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsAtLeast(1));

    // Verify object info
    expect(find.text('Project Task'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify the change text is displayed
    expect(find.textContaining('changed the due date'), findsOneWidget);
  });

  testWidgets('task complete', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.taskComplete.name,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockEmoji: '☑️',
        mockTitle: 'Project Task',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityTaskCompleteItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pumpAndSettle();

    // Verify action icon
    expect(find.byIcon(Icons.download_done), findsOneWidget);

    // Verify action title
    expect(find.text('Completed'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsAtLeast(1));

    // Verify object info
    expect(find.text('Project Task'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });

  testWidgets('task accepted', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.taskAccept.name,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockEmoji: '☑️',
        mockTitle: 'Project Task',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityTaskAcceptedItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pumpAndSettle();

    // Verify action icon
    expect(find.byIcon(Icons.done), findsOneWidget);

    // Verify action title
    expect(find.text('Accepted'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsAtLeast(1));

    // Verify object info
    expect(find.text('Project Task'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });

  testWidgets('task Decline', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.taskDecline.name,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockEmoji: '☑️',
        mockTitle: 'Project Task',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityTaskDeclineItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pumpAndSettle();

    // Verify action icon
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Verify action title
    expect(find.text('Declined'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsAtLeast(1));

    // Verify object info
    expect(find.text('Project Task'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });

  testWidgets('task re-opened', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.taskReOpen.name,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockEmoji: '☑️',
        mockTitle: 'Project Task',
      ),
    );

    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityTaskReOpenItemWidget(activity: mockActivity),
      ),
    );
    // Wait for the async provider to load
    await tester.pumpAndSettle();

    // Verify action icon
    expect(find.byIcon(Icons.restart_alt), findsOneWidget);

    // Verify action title
    expect(find.text('Re-opened'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsAtLeast(1));

    // Verify object info
    expect(find.text('Project Task'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });
}
