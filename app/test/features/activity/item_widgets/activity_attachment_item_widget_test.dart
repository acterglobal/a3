import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/attachment.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/test_util.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_activity_object.dart';

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
        child: ActivityAttachmentItemWidget(activity: mockActivity!),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
  }

  testWidgets('Add attachment on Pin Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.attachment.name,
      mockName: 'budget.mp4',
      mockSubType: 'video',
      mockObject: MockActivityObject(
        mockType: 'pin',
        mockEmoji: '📌',
        mockTitle: 'Pin Name',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.paperclip), findsOneWidget);

    // Verify action title
    expect(find.text('Added attachment on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.pushPin), findsAtLeast(1));

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsOneWidget);

    // Verify object info
    expect(find.text('Pin Name'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify attachment content
    expect(find.text('video : budget.mp4'), findsOneWidget);
  });

  testWidgets('Add attachment on Event Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockName: 'budget.mp4',
      mockSubType: 'video',
      mockType: PushStyles.attachment.name,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockEmoji: '🗓️',
        mockTitle: 'Team Meeting',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.paperclip), findsOneWidget);

    // Verify action title
    expect(find.text('Added attachment on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsAtLeast(1));

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsNothing);

    // Verify object info
    expect(find.text('Team Meeting'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify attachment content
    expect(find.text('video : budget.mp4'), findsOneWidget);
  });

  testWidgets('Add attachment on TaskList Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockName: 'budget.mp4',
      mockSubType: 'video',
      mockType: PushStyles.attachment.name,
      mockObject: MockActivityObject(
        mockType: 'task-list',
        mockEmoji: '📋',
        mockTitle: 'Project Tasks',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.paperclip), findsOneWidget);

    // Verify action title
    expect(find.text('Added attachment on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.listChecks), findsAtLeast(1));

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsOneWidget);

    // Verify object info
    expect(find.text('Project Tasks'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify attachment content
    expect(find.text('video : budget.mp4'), findsOneWidget);
  });

  testWidgets('Add attachment on TaskItem Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockName: 'budget.mp4',
      mockSubType: 'video',
      mockType: PushStyles.attachment.name,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockEmoji: '☑️',
        mockTitle: 'Complete Documentation',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.paperclip), findsOneWidget);

    // Verify action title
    expect(find.text('Added attachment on'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsAtLeast(1));

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsNothing);

    // Verify object info
    expect(find.text('Complete Documentation'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);

    // Verify attachment content
    expect(find.text('video : budget.mp4'), findsOneWidget);
  });
}
