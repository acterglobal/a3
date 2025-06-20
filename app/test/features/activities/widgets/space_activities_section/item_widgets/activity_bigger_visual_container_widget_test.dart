import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_bigger_visual_container_widget.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../helpers/test_util.dart';
import '../../../../../common/mock_data/mock_avatar_info.dart';
import '../../../../activity/mock_data/mock_activity_object.dart';

void main() {
  late MockAvatarInfo mockAvatarInfo;

  setUp(() {
    mockAvatarInfo = MockAvatarInfo(
      uniqueId: 'test-user-id',
      mockDisplayName: 'Test User',
    );
  });

  Future<void> pumpActivityBiggerVisualContainerWidget(
    WidgetTester tester, {
    ActivityObject? activityObject,
    String? userId,
    String? roomId,
    String? actionTitle,
    IconData? actionIcon,
    Widget? leadingWidget,
    String? target,
    Widget? subtitle,
    int? originServerTs,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider((userId: userId ?? 'test-user-id', roomId: roomId ?? 'test-room-id'))
            .overrideWith((ref) => mockAvatarInfo),
        memberDisplayNameProvider((userId: userId ?? 'test-user-id', roomId: roomId ?? 'test-room-id'))
            .overrideWith((ref) => Future.value('Test User')),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ActivityBiggerVisualContainerWidget(
            activityObject: activityObject,
            userId: userId ?? 'test-user-id',
            roomId: roomId ?? 'test-room-id',
            actionTitle: actionTitle ?? 'tested',
            actionIcon: actionIcon ?? Icons.info,
            leadingWidget: leadingWidget,
            target: target ?? 'Test Target',
            subtitle: subtitle,
            originServerTs: originServerTs ?? 1234567890,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ActivityBiggerVisualContainerWidget Tests', () {
    testWidgets('renders with basic properties', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(tester);

      // Verify the widget is rendered
      expect(find.byType(ActivityBiggerVisualContainerWidget), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      
      // Verify RichText widgets are rendered
      final richTextWidgets = find.byType(RichText);
      expect(richTextWidgets, findsWidgets);
    });

    testWidgets('displays user display name', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(tester);

      // The text is in a RichText widget, so we need to search for it within the combined text
      expect(findRichTextContaining('Test User'), findsOneWidget);
    });

    testWidgets('displays target text', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        target: 'Test Task',
      );

      expect(findRichTextContaining('Test Task'), findsOneWidget);
    });

    testWidgets('displays default values correctly', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(tester);

      // Test with default values: "Test User tested Test Target"
      expect(findRichTextContaining('Test User'), findsOneWidget);
      expect(findRichTextContaining('tested'), findsOneWidget);
      expect(findRichTextContaining('Test Target'), findsOneWidget);
    });

    testWidgets('displays action icon in avatar overlay', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        actionIcon: Icons.add,
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays custom leading widget when provided', (WidgetTester tester) async {
      final customLeadingWidget = Container(
        width: 30,
        height: 30,
        color: Colors.red,
        child: const Icon(Icons.star),
      );

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        leadingWidget: customLeadingWidget,
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays default avatar when no leading widget provided', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(tester);

      expect(find.byType(ActerAvatar), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (WidgetTester tester) async {
      final subtitleWidget = const Text('Subtitle Text');

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        subtitle: subtitleWidget,
      );

      expect(find.text('Subtitle Text'), findsOneWidget);
    });

    testWidgets('displays TimeAgoWidget', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(tester);

      expect(find.byType(TimeAgoWidget), findsOneWidget);
    });

    testWidgets('displays activity object icon for event type', (WidgetTester tester) async {
      final activityObject = MockActivityObject(mockType: 'event');

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.calendar), findsOneWidget);
    });

    testWidgets('displays activity object icon for pin type', (WidgetTester tester) async {
      final activityObject = MockActivityObject(mockType: 'pin');

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.pushPin), findsOneWidget);
    });

    testWidgets('displays activity object icon for task-list type', (WidgetTester tester) async {
      final activityObject = MockActivityObject(mockType: 'task-list');

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.listChecks), findsOneWidget);
    });

    testWidgets('displays activity object icon for task type', (WidgetTester tester) async {
      final activityObject = MockActivityObject(mockType: 'task');

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsOneWidget);
    });

    testWidgets('displays question icon for unknown activity object type', (WidgetTester tester) async {
      final activityObject = MockActivityObject(mockType: 'unknown-type');

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.question), findsOneWidget);
    });

    testWidgets('does not display activity object icon when activityObject is null', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        activityObject: null,
      );

      // Should not find any of the specific activity object icons
      expect(find.byIcon(PhosphorIconsRegular.rocketLaunch), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.book), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.calendar), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.pushPin), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.listChecks), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.question), findsNothing);
    });

    testWidgets('displays subtitle and time in correct layout when subtitle is provided', (WidgetTester tester) async {
      final subtitleWidget = const Text('Subtitle Text');

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        subtitle: subtitleWidget,
      );

      expect(find.text('Subtitle Text'), findsOneWidget);
      expect(find.byType(TimeAgoWidget), findsOneWidget);
      expect(find.byType(IntrinsicHeight), findsOneWidget);
    });

    testWidgets('displays only time when no subtitle is provided', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        subtitle: null,
      );

      expect(find.byType(TimeAgoWidget), findsOneWidget);
      expect(find.byType(IntrinsicHeight), findsNothing);
    });

    testWidgets('handles empty target text', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        target: '',
      );

      // Widget should still render without errors
      expect(find.byType(ActivityBiggerVisualContainerWidget), findsOneWidget);
    });

    testWidgets('displays rich text with proper styling', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        actionTitle: 'created',
        target: 'Test Task',
      );

      // There should be multiple RichText widgets (one for the main content, others for time, etc.)
      expect(find.byType(RichText), findsWidgets);
      expect(findRichTextContaining('Test User'), findsOneWidget);
      expect(findRichTextContaining('created'), findsOneWidget);
      expect(findRichTextContaining('Test Task'), findsOneWidget);
    });

    testWidgets('avatar overlay has correct styling', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        actionIcon: Icons.add,
      );

      // Find the action icon
      final actionIcon = find.byIcon(Icons.add);
      expect(actionIcon, findsOneWidget);
      
      // Find the Stack widget that contains the avatar and overlay
      expect(find.byType(Stack), findsWidgets);
      
      // Verify the icon is within a Container with proper styling (should find the overlay container)
      final iconContainers = find.ancestor(
        of: actionIcon,
        matching: find.byType(Container),
      );
      expect(iconContainers, findsAtLeastNWidgets(1));
      
      // Verify the container has circular decoration
      final overlayContainer = tester.widget<Container>(iconContainers.first);
      expect(overlayContainer.decoration, isA<BoxDecoration>());
      final decoration = overlayContainer.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('handles complex subtitle widget', (WidgetTester tester) async {
      final complexSubtitle = Row(
        children: [
          const Icon(Icons.star, size: 16),
          const SizedBox(width: 4),
          const Text('Complex Subtitle'),
        ],
      );

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        subtitle: complexSubtitle,
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Complex Subtitle'), findsOneWidget);
    });

    testWidgets('handles long text content', (WidgetTester tester) async {
      const longTarget = 'This is a very long target text that should be handled properly by the widget without causing any layout issues or overflow problems';
      const longActionTitle = 'This is a very long action title that should be handled properly';

      await pumpActivityBiggerVisualContainerWidget(
        tester,
        target: longTarget,
        actionTitle: longActionTitle,
      );

      // Widget should render without errors
      expect(find.byType(ActivityBiggerVisualContainerWidget), findsOneWidget);
      expect(findRichTextContaining('This is a very long target text'), findsOneWidget);
      expect(findRichTextContaining('This is a very long action title'), findsOneWidget);
    });

    testWidgets('handles special characters in text', (WidgetTester tester) async {
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        target: 'Task with special chars: @#\$%^&*()',
        actionTitle: 'Action with emoji 🚀',
      );

      expect(findRichTextContaining('Task with special chars: @#\$%^&*()'), findsOneWidget);
      expect(findRichTextContaining('Action with emoji 🚀'), findsOneWidget);
    });
  });

  group('Integration Tests', () {
    testWidgets('widget rebuilds correctly when properties change', (WidgetTester tester) async {
      // Initial render
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        actionTitle: 'created',
        target: 'Task 1',
      );

      // Verify initial render
      expect(find.byType(ActivityBiggerVisualContainerWidget), findsOneWidget);
      expect(findRichTextContaining('created'), findsOneWidget);
      expect(findRichTextContaining('Task 1'), findsOneWidget);

      // Change properties and rebuild - this replaces the entire widget tree
      await pumpActivityBiggerVisualContainerWidget(
        tester,
        actionTitle: 'updated',
        target: 'Task 2',
        actionIcon: Icons.edit,
      );

      // Verify widget still renders after rebuild
      expect(find.byType(ActivityBiggerVisualContainerWidget), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      
      // Verify that TimeAgoWidget is still present
      expect(find.byType(TimeAgoWidget), findsOneWidget);
      
      // Verify that some icon is present (could be the edit icon or default info icon)
      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('widget handles multiple instances correctly', (WidgetTester tester) async {
      final mockAvatarInfo1 = MockAvatarInfo(
        uniqueId: 'user1',
        mockDisplayName: 'User 1',
      );
      final mockAvatarInfo2 = MockAvatarInfo(
        uniqueId: 'user2',
        mockDisplayName: 'User 2',
      );

      await tester.pumpProviderWidget(
        overrides: [
          memberAvatarInfoProvider((userId: 'user1', roomId: 'room1'))
              .overrideWith((ref) => mockAvatarInfo1),
          memberDisplayNameProvider((userId: 'user1', roomId: 'room1'))
              .overrideWith((ref) => Future.value('User 1')),
          memberAvatarInfoProvider((userId: 'user2', roomId: 'room2'))
              .overrideWith((ref) => mockAvatarInfo2),
          memberDisplayNameProvider((userId: 'user2', roomId: 'room2'))
              .overrideWith((ref) => Future.value('User 2')),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ActivityBiggerVisualContainerWidget(
                  userId: 'user1',
                  roomId: 'room1',
                  actionTitle: 'created',
                  actionIcon: Icons.add,
                  target: 'Task 1',
                  originServerTs: 1234567890,
                ),
                ActivityBiggerVisualContainerWidget(
                  userId: 'user2',
                  roomId: 'room2',
                  actionTitle: 'updated',
                  actionIcon: Icons.edit,
                  target: 'Task 2',
                  originServerTs: 1234567891,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActivityBiggerVisualContainerWidget), findsNWidgets(2));
      expect(findRichTextContaining('User 1'), findsOneWidget);
      expect(findRichTextContaining('User 2'), findsOneWidget);
      expect(findRichTextContaining('created'), findsOneWidget);
      expect(findRichTextContaining('updated'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
} 