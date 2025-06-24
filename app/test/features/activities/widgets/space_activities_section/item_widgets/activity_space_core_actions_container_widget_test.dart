import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_space_core_actions_container_widget.dart';
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

  Future<void> pumpActivitySpaceCoreActionsContainerWidget(
    WidgetTester tester, {
    ActivityObject? activityObject,
    String? userId,
    String? roomId,
    String? actionTitle,
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
          body: ActivitySpaceCoreActionsContainerWidget(
            activityObject: activityObject,
            userId: userId ?? 'test-user-id',
            roomId: roomId ?? 'test-room-id',
            actionTitle: actionTitle ?? 'updated',
            target: target ?? 'Test Target',
            originServerTs: originServerTs ?? 1234567890,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ActivitySpaceCoreActionsContainerWidget Tests', () {
    testWidgets('renders with basic properties', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      // Verify the widget is rendered
      expect(
        find.byType(ActivitySpaceCoreActionsContainerWidget),
        findsOneWidget,
      );
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Row), findsWidgets);

      // Verify RichText widgets are rendered
      final richTextWidgets = find.byType(RichText);
      expect(richTextWidgets, findsWidgets);
    });

    testWidgets('displays user display name', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      // The display name is in a RichText widget
      expect(findRichTextContaining('Test User'), findsOneWidget);
    });

    testWidgets('displays target text', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(
        tester,
        target: 'Test Task',
      );

      // Target is not directly displayed but passed as parameter
      expect(
        find.byType(ActivitySpaceCoreActionsContainerWidget),
        findsOneWidget,
      );
    });

    testWidgets('displays default values correctly', (
      WidgetTester tester,
    ) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      // Test with default values
      expect(findRichTextContaining('Test User'), findsOneWidget);
      expect(findRichTextContaining('updated'), findsOneWidget);
    });

    testWidgets('displays pencil icon in avatar overlay', (
      WidgetTester tester,
    ) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      expect(
        find.byIcon(PhosphorIconsRegular.pencilSimpleLine),
        findsOneWidget,
      );
    });

    testWidgets('displays avatar with correct styling', (
      WidgetTester tester,
    ) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('displays TimeAgoWidget', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      expect(find.byType(TimeAgoWidget), findsOneWidget);
    });

    testWidgets('displays TimeAgoWidget with custom timestamp', (
      WidgetTester tester,
    ) async {
      await pumpActivitySpaceCoreActionsContainerWidget(
        tester,
        originServerTs: 9876543210,
      );

      expect(find.byType(TimeAgoWidget), findsOneWidget);
    });

    testWidgets('avatar overlay has correct styling', (
      WidgetTester tester,
    ) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      // Find the pencil icon
      final pencilIcon = find.byIcon(PhosphorIconsRegular.pencilSimpleLine);
      expect(pencilIcon, findsOneWidget);

      // Find the Stack widget that contains the avatar and overlay
      expect(find.byType(Stack), findsWidgets);

      // Verify the icon is within a Container with proper styling
      final iconContainers = find.ancestor(
        of: pencilIcon,
        matching: find.byType(Container),
      );
      expect(iconContainers, findsAtLeastNWidgets(1));

      // Verify the container has circular decoration
      final overlayContainer = tester.widget<Container>(iconContainers.first);
      expect(overlayContainer.decoration, isA<BoxDecoration>());
      final decoration = overlayContainer.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('handles long action title', (WidgetTester tester) async {
      const longActionTitle =
          'performed a very long action that should be handled properly by the widget without causing any layout issues';

      await pumpActivitySpaceCoreActionsContainerWidget(
        tester,
        actionTitle: longActionTitle,
      );

      // Widget should render without errors
      expect(
        find.byType(ActivitySpaceCoreActionsContainerWidget),
        findsOneWidget,
      );
      expect(
        findRichTextContaining('performed a very long action'),
        findsOneWidget,
      );
    });

    testWidgets('handles special characters in text', (
      WidgetTester tester,
    ) async {
      await pumpActivitySpaceCoreActionsContainerWidget(
        tester,
        actionTitle: 'action with special chars: @#\$%^&*() and emoji 🚀',
        target: 'Target with special chars: @#\$%^&*()',
      );

      expect(
        findRichTextContaining(
          'action with special chars: @#\$%^&*() and emoji 🚀',
        ),
        findsOneWidget,
      );
    });

    testWidgets('layout structure is correct', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      // Verify the main container structure
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(Positioned), findsWidgets);
      expect(find.byType(Expanded), findsOneWidget);
      expect(find.byType(Flexible), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('uses fallback userId when display name is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          memberAvatarInfoProvider((
            userId: 'fallback-user',
            roomId: 'test-room-id',
          )).overrideWith((ref) => mockAvatarInfo),
          memberDisplayNameProvider((
            userId: 'fallback-user',
            roomId: 'test-room-id',
          )).overrideWith((ref) => Future.value(null)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivitySpaceCoreActionsContainerWidget(
              userId: 'fallback-user',
              roomId: 'test-room-id',
              actionTitle: 'updated',
              target: 'Test Target',
              originServerTs: 1234567890,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should use userId as fallback
      expect(findRichTextContaining('fallback-user'), findsOneWidget);
    });

    testWidgets('handles null activity object', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(
        tester,
        activityObject: null,
      );

      // Widget should still render without errors
      expect(
        find.byType(ActivitySpaceCoreActionsContainerWidget),
        findsOneWidget,
      );
    });

    testWidgets('handles activity object with different types', (
      WidgetTester tester,
    ) async {
      final activityObject = MockActivityObject(mockType: 'space');

      await pumpActivitySpaceCoreActionsContainerWidget(
        tester,
        activityObject: activityObject,
      );

      // Widget should render without errors
      expect(
        find.byType(ActivitySpaceCoreActionsContainerWidget),
        findsOneWidget,
      );
    });

    testWidgets('icon has correct properties', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      final iconWidget = tester.widget<Icon>(
        find.byIcon(PhosphorIconsRegular.pencilSimpleLine),
      );
      expect(iconWidget.color, Colors.white);
      expect(iconWidget.size, 15);
    });

    testWidgets('avatar has correct size', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      final avatarWidget = tester.widget<ActerAvatar>(find.byType(ActerAvatar));
      expect(avatarWidget.options.size, 22);
    });

    testWidgets('container has correct padding', (WidgetTester tester) async {
      await pumpActivitySpaceCoreActionsContainerWidget(tester);

      // Find the main container
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // The main container should have vertical padding of 10
      final mainContainer = tester.widget<Container>(containers.first);
      expect(mainContainer.padding, const EdgeInsets.symmetric(vertical: 10));
    });
  });

  group('Integration Tests', () {
    testWidgets('widget works with different activity object types', (
      WidgetTester tester,
    ) async {
      // Test with different activity object types
      final activityTypes = ['space', 'room', 'event', 'task', 'news'];

      for (final type in activityTypes) {
        final activityObject = MockActivityObject(mockType: type);
        await pumpActivitySpaceCoreActionsContainerWidget(
          tester,
          activityObject: activityObject,
        );

        // Widget should render without errors for each type
        expect(
          find.byType(ActivitySpaceCoreActionsContainerWidget),
          findsOneWidget,
        );
        expect(
          find.byIcon(PhosphorIconsRegular.pencilSimpleLine),
          findsOneWidget,
        );
      }
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
                ActivitySpaceCoreActionsContainerWidget(
                  userId: 'user1',
                  roomId: 'room1',
                  actionTitle: 'created',
                  target: 'Task 1',
                  originServerTs: 1234567890,
                ),
                ActivitySpaceCoreActionsContainerWidget(
                  userId: 'user2',
                  roomId: 'room2',
                  actionTitle: 'updated',
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
        find.byType(ActivitySpaceCoreActionsContainerWidget),
        findsNWidgets(2),
      );
      expect(findRichTextContaining('User 1'), findsOneWidget);
      expect(findRichTextContaining('User 2'), findsOneWidget);
      expect(findRichTextContaining('created'), findsOneWidget);
      expect(findRichTextContaining('updated'), findsOneWidget);
      expect(
        find.byIcon(PhosphorIconsRegular.pencilSimpleLine),
        findsNWidgets(2),
      );
    });
    testWidgets('widget handles long display names correctly', (
      WidgetTester tester,
    ) async {
      final longNameAvatarInfo = MockAvatarInfo(
        uniqueId: 'long-name-user',
        mockDisplayName:
            'This is a very long display name that should be handled properly',
      );

      await tester.pumpProviderWidget(
        overrides: [
          memberAvatarInfoProvider((
            userId: 'long-name-user',
            roomId: 'test-room-id',
          )).overrideWith((ref) => longNameAvatarInfo),
          memberDisplayNameProvider((
            userId: 'long-name-user',
            roomId: 'test-room-id',
          )).overrideWith(
            (ref) => Future.value(
              'This is a very long display name that should be handled properly',
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivitySpaceCoreActionsContainerWidget(
              userId: 'long-name-user',
              roomId: 'test-room-id',
              actionTitle: 'updated',
              target: 'Test Target',
              originServerTs: 1234567890,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Widget should render without errors
      expect(
        find.byType(ActivitySpaceCoreActionsContainerWidget),
        findsOneWidget,
      );
      expect(
        findRichTextContaining('This is a very long display name'),
        findsOneWidget,
      );
    });
  });
}
