import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/references.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/test_util.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_activity_object.dart';
import '../mock_data/mock_ref_details.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    MockActivity? mockActivity,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider.overrideWith(
          (ref, param) =>
              MockAvatarInfo(uniqueId: param.userId, mockDisplayName: 'User-1'),
        ),
      ],
      child: Material(
        child: ActivityReferencesItemWidget(activity: mockActivity!),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
  }

  testWidgets('Add reference on Pin Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.references.name,
      mockObject: MockActivityObject(
        mockType: SpaceObjectTypes.pin.name,
        mockEmoji: SpaceObjectTypes.pin.emoji,
        mockTitle: 'Pin Name',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Event Name',
        mockType: SpaceObjectTypes.event.name,
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action title
    expect(
      find.text('${PushStyles.references.emoji} Added references on'),
      findsOneWidget,
    );

    // Verify object info
    expect(find.text('${SpaceObjectTypes.pin.emoji} Pin Name'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify comment content
    expect(
      find.text('${SpaceObjectTypes.event.emoji} Event Name'),
      findsOneWidget,
    );
  });

  testWidgets('Add reference on Event Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.references.name,
      mockObject: MockActivityObject(
        mockType: SpaceObjectTypes.event.name,
        mockEmoji: SpaceObjectTypes.event.emoji,
        mockTitle: 'Team Meeting',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Task List Name',
        mockType: SpaceObjectTypes.taskList.name,
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action title
    expect(
      find.text('${PushStyles.references.emoji} Added references on'),
      findsOneWidget,
    );

    // Verify object info
    expect(
      find.text('${SpaceObjectTypes.event.emoji} Team Meeting'),
      findsOneWidget,
    );

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify reference content
    expect(
      find.text('${SpaceObjectTypes.taskList.emoji} Task List Name'),
      findsOneWidget,
    );
  });

  testWidgets('Add reference on TaskList Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.references.name,
      mockObject: MockActivityObject(
        mockType: SpaceObjectTypes.taskList.name,
        mockEmoji: SpaceObjectTypes.taskList.emoji,
        mockTitle: 'Project Tasks',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Task Name',
        mockType: SpaceObjectTypes.taskItem.name,
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action title
    expect(
      find.text('${PushStyles.references.emoji} Added references on'),
      findsOneWidget,
    );

    // Verify object info
    expect(
      find.text('${SpaceObjectTypes.taskList.emoji} Project Tasks'),
      findsOneWidget,
    );

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify reference content
    expect(
      find.text('${SpaceObjectTypes.taskItem.emoji} Task Name'),
      findsOneWidget,
    );
  });

  testWidgets('Add reference on TaskItem Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.references.name,
      mockObject: MockActivityObject(
        mockType: SpaceObjectTypes.taskItem.name,
        mockEmoji: SpaceObjectTypes.taskItem.emoji,
        mockTitle: 'Complete Documentation',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Pin Name',
        mockType: SpaceObjectTypes.pin.name,
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action title
    expect(
      find.text('${PushStyles.references.emoji} Added references on'),
      findsOneWidget,
    );

    // Verify object info
    expect(
      find.text('${SpaceObjectTypes.taskItem.emoji} Complete Documentation'),
      findsOneWidget,
    );

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify reference content
    expect(find.text('${SpaceObjectTypes.pin.emoji} Pin Name'), findsOneWidget);
  });
}
