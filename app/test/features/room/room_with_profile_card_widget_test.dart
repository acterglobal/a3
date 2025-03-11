import 'package:acter/common/widgets/room/room_with_profile_card.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_util.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    required String roomId,
    required AvatarInfo avatarInfo,
    List<AvatarInfo>? parents,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    ValueChanged<bool>? onFocusChange,
    double avatarSize = 40,
    EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
    ShapeBorder? shape,
    bool showParents = true,
    bool showSuggestedMark = false,
    bool showVisibilityMark = false,
    bool showBookmarkedIndicator = false,
    EdgeInsetsGeometry? margin,
  }) async {
    await tester.pumpProviderWidget(
      child: MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        home: Scaffold(
          body: RoomWithAvatarInfoCard(
            roomId: roomId,
            avatarInfo: avatarInfo,
            parents: parents,
            subtitle: Text('Subtitle'),
            leading: leading,
            trailing: trailing,
            onTap: onTap,
            onLongPress: onLongPress,
            onFocusChange: onFocusChange,
            avatarSize: avatarSize,
            contentPadding: contentPadding,
            shape: shape,
            showParents: showParents,
            showSuggestedMark: showSuggestedMark,
            showVisibilityMark: showVisibilityMark,
            showBookmarkedIndicator: showBookmarkedIndicator,
            margin: margin,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RoomWithAvatarInfoCard', () {
    final avatarInfo = AvatarInfo(
      uniqueId: 'room1',
      displayName: 'Room 1',
      avatar: NetworkImage('https://example.com/avatar.jpg'),
    );

    testWidgets('displays room title correctly', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        showParents: false,
      );

      expect(find.text('Room 1'), findsOneWidget);
    });

    testWidgets('displays avatar correctly', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        showParents: false,
      );

      expect(find.byType(ActerAvatar), findsOneWidget);
    });

    testWidgets('displays margin correctly', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        margin: EdgeInsets.all(20),
        showParents: false,
      );

      // Verify the margin is applied correctly (check if it affects the layout)
      final container = tester.firstWidget(find.byType(Card)) as Card;
      expect(container.margin, EdgeInsets.all(20));
    });

    testWidgets('executes onTap callback when tapped', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        onTap: () {
          tapped = true;
        },
        showParents: false,
      );

      await tester.tap(find.byType(RoomWithAvatarInfoCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('executes onLongPress callback when long-pressed', (
      WidgetTester tester,
    ) async {
      bool longPressed = false;

      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        onLongPress: () {
          longPressed = true;
        },
        showParents: false,
      );

      await tester.longPress(find.byType(RoomWithAvatarInfoCard));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('shows parent badges when showParents is true', (
      WidgetTester tester,
    ) async {
      final parents = [
        AvatarInfo(
          uniqueId: 'parent1',
          displayName: 'Parent 1',
          avatar: NetworkImage('https://example.com/avatar/parent1.jpg'),
        ),
      ];

      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        showParents: true,
        parents: parents,
      );

      expect(
        find.byType(ActerAvatar),
        findsNWidgets(2),
      ); // Avatar for the room and its parent
    });

    testWidgets('does not show parents badges when showParents is false', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        showParents: false,
      );

      expect(
        find.byType(ActerAvatar),
        findsOneWidget,
      ); // Only one avatar (room)
    });

    testWidgets('shows suggested mark when showSuggestedMark is true', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        showSuggestedMark: true,
        showParents: false,
      );

      expect(find.text('Suggested'), findsOneWidget);
    });

    testWidgets('do not shows suggested mark when showSuggestedMark is false', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        showSuggestedMark: false,
        showParents: false,
      );

      expect(find.text('Suggested'), findsNothing);
    });

    testWidgets(
      'shows bookmark indicator when showBookmarkedIndicator is true',
      (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room1',
          avatarInfo: avatarInfo,
          avatarSize: 40,
          contentPadding: EdgeInsets.zero,
          showBookmarkedIndicator: true,
          showParents: false,
        );

        expect(find.byIcon(Icons.bookmark_sharp), findsOneWidget);
      },
    );

    testWidgets('does not show bookmark indicator when isBookmarked is false', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        showBookmarkedIndicator: false,
        showParents: false,
      );

      expect(find.byIcon(Icons.bookmark_sharp), findsNothing);
    });

    testWidgets('handles custom leading and trailing widgets', (
      WidgetTester tester,
    ) async {
      final leadingWidget = Icon(Icons.access_alarm);
      final trailingWidget = Icon(Icons.accessibility_new);

      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room1',
        avatarInfo: avatarInfo,
        avatarSize: 40,
        contentPadding: EdgeInsets.zero,
        leading: leadingWidget,
        trailing: trailingWidget,
        showParents: false,
      );

      expect(
        find.byIcon(Icons.access_alarm),
        findsOneWidget,
      ); // Leading widget check
      expect(
        find.byIcon(Icons.accessibility_new),
        findsOneWidget,
      ); // Trailing widget check
    });
  });
}
