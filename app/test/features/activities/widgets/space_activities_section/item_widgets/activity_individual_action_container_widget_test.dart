import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_individual_action_container_widget.dart';
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

  Future<void> pumpActivityIndividualActionContainerWidget(
    WidgetTester tester, {
    ActivityObject? activityObject,
    String? userId,
    String? roomId,
    String? actionTitle,
    IconData? actionIcon,
    Color? actionIconBgColor,
    Color? actionIconColor,
    String? target,
    int? originServerTs,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider((
          userId: userId ?? 'test-user-id',
          roomId: roomId ?? 'test-room-id',
        )).overrideWith((ref) => mockAvatarInfo),
        memberDisplayNameProvider((
          userId: userId ?? 'test-user-id',
          roomId: roomId ?? 'test-room-id',
        )).overrideWith((ref) => Future.value('Test User')),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ActivityIndividualActionContainerWidget(
            activityObject: activityObject,
            userId: userId ?? 'test-user-id',
            roomId: roomId ?? 'test-room-id',
            actionTitle: actionTitle ?? 'tested',
            actionIcon: actionIcon ?? Icons.info,
            actionIconBgColor: actionIconBgColor,
            actionIconColor: actionIconColor,
            target: target ?? 'Test Target',
            originServerTs: originServerTs ?? 1234567890,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ActivityIndividualActionContainerWidget Tests', () {
    testWidgets('renders with basic properties', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(tester);

      // Verify the widget is rendered
      expect(
        find.byType(ActivityIndividualActionContainerWidget),
        findsOneWidget,
      );
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Column), findsWidgets);

      // Verify RichText widgets are rendered
      final richTextWidgets = find.byType(RichText);
      expect(richTextWidgets, findsWidgets);
    });

    testWidgets('displays user display name', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(tester);

      // The display name is in a RichText widget
      expect(findRichTextContaining('Test User'), findsOneWidget);
    });

    testWidgets('displays action title', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        actionTitle: 'created',
      );

      expect(findRichTextContaining('created'), findsOneWidget);
    });

    testWidgets('displays target text', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        target: 'Test Task',
      );

      expect(find.text('Test Task'), findsOneWidget);
    });

    testWidgets('displays default values correctly', (
      WidgetTester tester,
    ) async {
      await pumpActivityIndividualActionContainerWidget(tester);

      // Test with default values
      expect(findRichTextContaining('Test User'), findsOneWidget);
      expect(findRichTextContaining('tested'), findsOneWidget);
      expect(find.text('Test Target'), findsOneWidget);
    });

    testWidgets('displays action icon in avatar overlay', (
      WidgetTester tester,
    ) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        actionIcon: Icons.add,
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays custom action icon colors', (
      WidgetTester tester,
    ) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        actionIcon: Icons.add,
        actionIconBgColor: Colors.red,
        actionIconColor: Colors.blue,
      );

      // Find the action icon
      final actionIcon = find.byIcon(Icons.add);
      expect(actionIcon, findsOneWidget);

      // Find the Stack widget that contains the avatar and overlay
      expect(find.byType(Stack), findsWidgets);

      // Verify the icon is within a Container with proper styling
      final iconContainers = find.ancestor(
        of: actionIcon,
        matching: find.byType(Container),
      );
      expect(iconContainers, findsAtLeastNWidgets(1));

      // Verify the container has circular decoration with custom colors
      final overlayContainer = tester.widget<Container>(iconContainers.first);
      expect(overlayContainer.decoration, isA<BoxDecoration>());
      final decoration = overlayContainer.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, Colors.red);
    });

    testWidgets('displays default avatar', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(tester);

      expect(find.byType(ActerAvatar), findsOneWidget);
    });

    testWidgets('displays TimeAgoWidget', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(tester);

      expect(find.byType(TimeAgoWidget), findsOneWidget);
    });

    testWidgets('displays activity object icon for event type', (
      WidgetTester tester,
    ) async {
      final activityObject = MockActivityObject(mockType: 'event');

      await pumpActivityIndividualActionContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.calendar), findsOneWidget);
    });

    testWidgets('displays activity object icon for pin type', (
      WidgetTester tester,
    ) async {
      final activityObject = MockActivityObject(mockType: 'pin');

      await pumpActivityIndividualActionContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.pushPin), findsOneWidget);
    });

    testWidgets('displays activity object icon for task-list type', (
      WidgetTester tester,
    ) async {
      final activityObject = MockActivityObject(mockType: 'task-list');

      await pumpActivityIndividualActionContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.listChecks), findsOneWidget);
    });

    testWidgets('displays activity object icon for task type', (
      WidgetTester tester,
    ) async {
      final activityObject = MockActivityObject(mockType: 'task');

      await pumpActivityIndividualActionContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.checkCircle), findsOneWidget);
    });

    testWidgets('displays question icon for unknown activity object type', (
      WidgetTester tester,
    ) async {
      final activityObject = MockActivityObject(mockType: 'unknown-type');

      await pumpActivityIndividualActionContainerWidget(
        tester,
        activityObject: activityObject,
      );

      expect(find.byIcon(PhosphorIconsRegular.question), findsOneWidget);
    });

    testWidgets(
      'does not display activity object icon when activityObject is null',
      (WidgetTester tester) async {
        await pumpActivityIndividualActionContainerWidget(
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
      },
    );

    testWidgets('displays target text with correct layout', (
      WidgetTester tester,
    ) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        target: 'Custom Target Text',
      );

      expect(find.text('Custom Target Text'), findsOneWidget);

      // Verify the text is in a Flexible widget for proper overflow handling
      final targetText = find.text('Custom Target Text');
      final flexibleAncestor = find.ancestor(
        of: targetText,
        matching: find.byType(Flexible),
      );
      expect(flexibleAncestor, findsOneWidget);
    });

    testWidgets('displays display name and action in bottom row', (
      WidgetTester tester,
    ) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        actionTitle: 'updated',
      );

      // Both display name and action should be in the same RichText
      expect(findRichTextContaining('Test User updated'), findsOneWidget);
    });

    testWidgets('handles empty target text', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(tester, target: '');

      // Widget should still render without errors
      expect(
        find.byType(ActivityIndividualActionContainerWidget),
        findsOneWidget,
      );
    });

    testWidgets('handles empty action title', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        actionTitle: '',
      );

      // Widget should still render without errors
      expect(
        find.byType(ActivityIndividualActionContainerWidget),
        findsOneWidget,
      );
    });

    testWidgets('avatar overlay has correct styling with default colors', (
      WidgetTester tester,
    ) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        actionIcon: Icons.add,
      );

      // Find the action icon
      final actionIcon = find.byIcon(Icons.add);
      expect(actionIcon, findsOneWidget);

      // Find the Stack widget that contains the avatar and overlay
      expect(find.byType(Stack), findsWidgets);

      // Verify the icon is within a Container with proper styling
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

    testWidgets('handles long target text with ellipsis', (
      WidgetTester tester,
    ) async {
      const longTarget =
          'This is a very long target text that should be handled properly by the widget without causing any layout issues or overflow problems and should show ellipsis';

      await pumpActivityIndividualActionContainerWidget(
        tester,
        target: longTarget,
      );

      // Widget should render without errors
      expect(
        find.byType(ActivityIndividualActionContainerWidget),
        findsOneWidget,
      );
      expect(
        find.textContaining('This is a very long target text'),
        findsOneWidget,
      );

      // Verify the text widget has maxLines and overflow properties
      final targetTextWidget = tester.widget<Text>(
        find.textContaining('This is a very long target text'),
      );
      expect(targetTextWidget.maxLines, 1);
      expect(targetTextWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('handles special characters in text', (
      WidgetTester tester,
    ) async {
      await pumpActivityIndividualActionContainerWidget(
        tester,
        target: 'Task with special chars: @#\$%^&*()',
        actionTitle: 'Action with emoji 🚀',
      );

      expect(
        find.textContaining('Task with special chars: @#\$%^&*()'),
        findsOneWidget,
      );
      expect(findRichTextContaining('Action with emoji 🚀'), findsOneWidget);
    });

    testWidgets('layout structure is correct', (WidgetTester tester) async {
      await pumpActivityIndividualActionContainerWidget(tester);

      // Verify the main container structure
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(Positioned), findsWidgets);
    });
  });

  group('Integration Tests', () {
    testWidgets('widget rebuilds correctly when properties change', (
      WidgetTester tester,
    ) async {
      // Initial render
      await pumpActivityIndividualActionContainerWidget(
        tester,
        actionTitle: 'created',
        target: 'Task 1',
      );

      // Verify initial render
      expect(
        find.byType(ActivityIndividualActionContainerWidget),
        findsOneWidget,
      );
      expect(findRichTextContaining('created'), findsOneWidget);
      expect(find.text('Task 1'), findsOneWidget);

      // Change properties and rebuild - this replaces the entire widget tree
      await pumpActivityIndividualActionContainerWidget(
        tester,
        actionTitle: 'updated',
        target: 'Task 2',
        actionIcon: Icons.edit,
      );

      // Verify widget still renders after rebuild
      expect(
        find.byType(ActivityIndividualActionContainerWidget),
        findsOneWidget,
      );
      expect(find.byType(RichText), findsWidgets);

      // Verify that TimeAgoWidget is still present
      expect(find.byType(TimeAgoWidget), findsOneWidget);

      // Verify that some icon is present (could be the edit icon or default info icon)
      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });
    testWidgets('widget handles multiple instances correctly', (
      WidgetTester tester,
    ) async {
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
          memberAvatarInfoProvider((
            userId: 'user1',
            roomId: 'room1',
          )).overrideWith((ref) => mockAvatarInfo1),
          memberDisplayNameProvider((
            userId: 'user1',
            roomId: 'room1',
          )).overrideWith((ref) => Future.value('User 1')),
          memberAvatarInfoProvider((
            userId: 'user2',
            roomId: 'room2',
          )).overrideWith((ref) => mockAvatarInfo2),
          memberDisplayNameProvider((
            userId: 'user2',
            roomId: 'room2',
          )).overrideWith((ref) => Future.value('User 2')),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ActivityIndividualActionContainerWidget(
                  userId: 'user1',
                  roomId: 'room1',
                  actionTitle: 'created',
                  actionIcon: Icons.add,
                  target: 'Task 1',
                  originServerTs: 1234567890,
                ),
                ActivityIndividualActionContainerWidget(
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

      expect(
        find.byType(ActivityIndividualActionContainerWidget),
        findsNWidgets(2),
      );
      expect(findRichTextContaining('User 1'), findsOneWidget);
      expect(findRichTextContaining('User 2'), findsOneWidget);
      expect(findRichTextContaining('created'), findsOneWidget);
      expect(findRichTextContaining('updated'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('widget handles different icon color combinations', (
      WidgetTester tester,
    ) async {
      // Test with different color combinations
      final colorCombinations = [
        {'bg': Colors.red, 'icon': Colors.white},
        {'bg': Colors.blue, 'icon': Colors.yellow},
        {'bg': Colors.green, 'icon': Colors.black},
      ];

      for (final combination in colorCombinations) {
        await pumpActivityIndividualActionContainerWidget(
          tester,
          actionIcon: Icons.star,
          actionIconBgColor: combination['bg'] as Color,
          actionIconColor: combination['icon'] as Color,
        );

        // Widget should render without errors for each color combination
        expect(
          find.byType(ActivityIndividualActionContainerWidget),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.star), findsOneWidget);
      }
    });
  });
}
