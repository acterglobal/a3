import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/references.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
        mockType: 'pin',
        mockEmoji: '📌',
        mockTitle: 'Pin Name',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Team Meeting',
        mockType: 'calendar-event',
        mockTargetId: 'event-id',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Wait for the widget to be fully built
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.link), findsOneWidget);

    // Verify action title
    expect(find.text('Added references on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.pushPin), findsAtLeast(1));

    // Verify object title
    expect(find.text('Pin Name'), findsOneWidget);

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsAtLeast(1));

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify reference object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsOneWidget);

    // Verify reference object title
    expect(find.text('Team Meeting'), findsOneWidget);
  });

  testWidgets('Add reference on Event Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.references.name,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockEmoji: '🗓️',
        mockTitle: 'Team Meeting',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Project Planning',
        mockType: 'pin',
        mockTargetId: 'pin-id',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Wait for the widget to be fully built
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.link), findsOneWidget);

    // Verify action title
    expect(find.text('Added references on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsAtLeast(1));

    // Verify object title
    expect(find.text('Team Meeting'), findsOneWidget);

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsAtLeast(1));

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify reference object icon
    expect(find.byIcon(PhosphorIconsRegular.pushPin), findsOneWidget);

    // Verify reference object title
    expect(find.text('Project Planning'), findsOneWidget);
  });

  testWidgets('Add reference on Task-list Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.references.name,
      mockObject: MockActivityObject(
        mockType: 'task-list',
        mockEmoji: '📋',
        mockTitle: 'Project Tasks',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Team Meeting',
        mockType: 'calendar-event',
        mockTargetId: 'event-id',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Wait for the widget to be fully built
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.link), findsOneWidget);

    // Verify action title
    expect(find.text('Added references on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.listChecks), findsAtLeast(1));

    // Verify object title
    expect(find.text('Project Tasks'), findsOneWidget);

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsAtLeast(1));

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify reference object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsOneWidget);

    // Verify reference object title
    expect(find.text('Team Meeting'), findsOneWidget);
  });

  testWidgets('Add reference on TaskItem Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.references.name,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockEmoji: '☑️',
        mockTitle: 'Complete Documentation',
      ),
      mockRefDetails: MockRefDetails(
        mockTitle: 'Team Meeting',
        mockType: 'calendar-event',
        mockTargetId: 'event-id',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Wait for the widget to be fully built
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.link), findsOneWidget);

    // Verify action title
    expect(find.text('Added references on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsAtLeast(1));

    // Verify object title
    expect(find.text('Complete Documentation'), findsOneWidget);

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsNothing);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify reference object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsOneWidget);

    // Verify reference object title
    expect(find.text('Team Meeting'), findsOneWidget);
  });
}
