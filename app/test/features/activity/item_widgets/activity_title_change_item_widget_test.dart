import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/titleChange.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/test_util.dart';
import '../mock_data/mock_activity.dart';
import '../mock_data/mock_activity_object.dart';
import '../mock_data/mock_title_change.dart';

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
        child: ActivityTitleChangeItemWidget(activity: mockActivity!),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
  }

  testWidgets('Title changes of Pin Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.titleChange.name,
      mockObject: MockActivityObject(
        mockType: 'pin',
        mockEmoji: '📌',
        mockTitle: 'Pin Name',
      ),
      mockTitleContent: MockTitleContent(
        mockChange: 'Changed',
        mockNewVal: 'mock-new-val',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Wait for the widget to be fully built
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.pencilLine), findsOneWidget);

    // Verify the change text is displayed
    expect(find.textContaining('changed the title'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.pushPin), findsAtLeast(1));

    // Verify object title
    expect(find.text('Pin Name'), findsOneWidget);

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsAtLeast(1));

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });

  testWidgets('Title changes of calendar event Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.titleChange.name,
      mockObject: MockActivityObject(
        mockType: 'event',
        mockEmoji: '🗓️',
        mockTitle: 'Team Meeting',
      ),
      mockTitleContent: MockTitleContent(
        mockChange: 'Changed',
        mockNewVal: 'mock-new-val',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Wait for the widget to be fully built
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.pencilLine), findsOneWidget);

    // Verify the change text is displayed
    expect(find.textContaining('changed the title'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.calendar), findsAtLeast(1));

    // Verify object title
    expect(find.text('Team Meeting'), findsOneWidget);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });

  testWidgets('Title changes of Task-list Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.titleChange.name,
      mockObject: MockActivityObject(
        mockType: 'task-list',
        mockEmoji: '📋',
        mockTitle: 'Project Tasks',
      ),
      mockTitleContent: MockTitleContent(
        mockChange: 'Changed',
        mockNewVal: 'mock-new-val',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Wait for the widget to be fully built
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.pencilLine), findsOneWidget);

    // Verify the change text is displayed
    expect(find.textContaining('changed the title'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.listChecks), findsAtLeast(1));

    // Verify object title
    expect(find.text('Project Tasks'), findsOneWidget);

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsAtLeast(1));

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });

  testWidgets('Title changes of TaskItem Object', (tester) async {
    MockActivity mockActivity = MockActivity(
      mockType: PushStyles.titleChange.name,
      mockObject: MockActivityObject(
        mockType: 'task',
        mockEmoji: '☑️',
        mockTitle: 'Complete Documentation',
      ),
      mockTitleContent: MockTitleContent(
        mockChange: 'Changed',
        mockNewVal: 'mock-new-val',
      ),
    );
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Wait for the widget to be fully built
    await tester.pump();

    // Verify action icon
    expect(find.byIcon(PhosphorIconsRegular.pencilLine), findsOneWidget);

    // Verify the change text is displayed
    expect(find.textContaining('changed the title'), findsOneWidget);

    // Verify object icon
    expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsAtLeast(1));

    // Verify object title
    expect(find.text('Complete Documentation'), findsOneWidget);

    // Verify Activity Object icon
    expect(find.byType(ActerIconWidget), findsNothing);

    // Verify user info
    expect(find.text('User-1'), findsOneWidget);
  });
}
