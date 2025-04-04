import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_util.dart';
import '../mock_data/mock_avatar_info.dart';
import 'package:acter_avatar/acter_avatar.dart';

void main() {
  group('Typing Indicator Widget Tests', () {
    testWidgets('should display single user typing', (tester) async {
      final testUser = AvatarInfo(
        uniqueId: 'test_user',
        displayName: 'Test User',
      );

      await tester.pumpProviderWidget(
        child: TypingIndicator(
          options: TypingIndicatorOptions(typingUsers: [testUser]),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // verify both name, avatar and animated circles are shown
      expect(find.text('Test User is typing'), findsOneWidget);
      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.byType(AnimatedCircles), findsOneWidget);
    });

    testWidgets('should display multiple users typing', (tester) async {
      final testUser = AvatarInfo(
        uniqueId: 'test_user',
        displayName: 'Test User',
      );
      final testUser2 = AvatarInfo(
        uniqueId: 'test_user2',
        displayName: 'Test User 2',
      );

      await tester.pumpProviderWidget(
        child: TypingIndicator(
          options: TypingIndicatorOptions(typingUsers: [testUser, testUser2]),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // verify the text contains the display names
      expect(find.text('Test User and Test User 2 are typing'), findsOneWidget);
      expect(find.byType(ActerAvatar), findsNWidgets(2));
      expect(find.byType(AnimatedCircles), findsOneWidget);
    });

    testWidgets('should display multiple users typing', (tester) async {
      final options = TypingIndicatorOptions(
        typingUsers: [
          MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
          MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'Bob'),
          MockAvatarInfo(uniqueId: 'user3', mockDisplayName: 'Charlie'),
        ],
      );

      await tester.pumpProviderWidget(child: TypingIndicator(options: options));

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ActerAvatar), findsNWidgets(2));
      // verify the rest count of users avatar
      expect(find.text('1'), findsOneWidget);
      // verify the text contains the display name
      expect(
        find.textContaining('Alice and 2 others are typing'),
        findsOneWidget,
      );

      expect(find.byType(AnimatedCircles), findsOneWidget);
    });
  });

  group('Avatar Handler and LTR-RTL support unit tests', () {
    testWidgets('should handle empty users list', (tester) async {
      await tester.pumpProviderWidget(child: AvatarHandler(users: const []));

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(TypingAvatar), findsNothing);
    });

    testWidgets('should handle single user correctly in LTR', (tester) async {
      await tester.pumpProviderWidget(
        child: AvatarHandler(
          users: [MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice')],
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TypingAvatar), findsOneWidget);
      expect(find.byType(Align), findsOneWidget);

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, equals(Alignment.centerLeft));
    });

    testWidgets('should handle single user correctly in RTL', (tester) async {
      await tester.pumpProviderWidget(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AvatarHandler(
            users: [MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'آدم')],
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TypingAvatar), findsOneWidget);
      expect(find.byType(Align), findsOneWidget);

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, equals(Alignment.centerRight));
    });

    testWidgets('should handle two users correctly in LTR', (tester) async {
      await tester.pumpProviderWidget(
        child: AvatarHandler(
          users: [
            MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
            MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'Bob'),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TypingAvatar), findsNWidgets(2));
      expect(find.byType(Stack), findsNWidgets(2));
      expect(find.byType(Positioned), findsOneWidget);

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.left, equals(16));
      expect(positioned.right, isNull);
    });

    testWidgets('should handle two users correctly in RTL', (tester) async {
      await tester.pumpProviderWidget(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AvatarHandler(
            users: [
              MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'آدم'),
              MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'باسم'),
            ],
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TypingAvatar), findsNWidgets(2));
      expect(find.byType(Stack), findsNWidgets(2));
      expect(find.byType(Positioned), findsOneWidget);

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.left, isNull);
      expect(positioned.right, equals(16));
    });

    testWidgets('should handle multiple users correctly in LTR', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        child: AvatarHandler(
          users: [
            MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
            MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'Bob'),
            MockAvatarInfo(uniqueId: 'user3', mockDisplayName: 'Charlie'),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TypingAvatar), findsNWidgets(2));
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      final positionedWidgets = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      final List<Positioned> positioned = positionedWidgets.toList();

      expect(positioned[0].left, equals(16));
      expect(positioned[0].right, isNull);

      expect(positioned[1].left, equals(32));
      expect(positioned[1].right, isNull);
    });

    testWidgets('should handle multiple users correctly in RTL', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AvatarHandler(
            users: [
              MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'آدم'),
              MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'باسم'),
              MockAvatarInfo(uniqueId: 'user3', mockDisplayName: 'جمال'),
              MockAvatarInfo(uniqueId: 'user4', mockDisplayName: 'داوود'),
            ],
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TypingAvatar), findsNWidgets(2));
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      final positionedWidgets = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      final List<Positioned> positioned = positionedWidgets.toList();

      expect(positioned[0].left, isNull);
      expect(positioned[0].right, equals(16));

      expect(positioned[1].left, isNull);
      expect(positioned[1].right, equals(32));
    });
  });

  group('Animated Circles Unit Tests', () {
    final theme = TypingIndicatorTheme(
      animatedCirclesColor: Colors.blue,
      multipleUserTextStyle: const TextStyle(fontSize: 12),
      countAvatarColor: Colors.grey,
      countTextColor: Colors.white,
    );

    testWidgets('should render three circles', (tester) async {
      await tester.pumpProviderWidget(child: AnimatedCircles(theme: theme));

      await tester.pump(const Duration(milliseconds: 300));

      // verify three animated circles
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.length, equals(3));
    });
  });
}
