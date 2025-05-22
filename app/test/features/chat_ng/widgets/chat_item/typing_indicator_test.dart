import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/typing_indicator.dart'
    show AnimatedCircles;
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import '../../../../helpers/test_util.dart';
import '../../../../common/mock_data/mock_avatar_info.dart';

void main() {
  group('TypingIndicator Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      List<User> typingUsers = const [],
      bool isDM = false,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          chatTypingEventProvider.overrideWith(
            (ref, roomId) => Stream.value(typingUsers),
          ),
          isDirectChatProvider.overrideWith((ref, roomId) => isDM),
          memberAvatarInfoProvider.overrideWith(
            (ref, info) => MockAvatarInfo(
              uniqueId: info.userId,
              mockDisplayName: info.userId == 'user1' ? 'Alice' : 'Bob',
            ),
          ),
        ],
        child: TypingIndicator(roomId: 'mock-room-1', isSelected: false),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show nothing when no users are typing', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets(
      'should show only animated circles for DM with one typing user',
      (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          typingUsers: [User(id: 'user1')],
          isDM: true,
        );
        expect(find.byType(AnimatedCircles), findsOneWidget);
        expect(find.byType(Text), findsNothing);
      },
    );

    testWidgets(
      'should show typing text and animated circles for non-DM with one typing user',
      (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          typingUsers: [User(id: 'user1')],
          isDM: false,
        );
        expect(find.byType(AnimatedCircles), findsOneWidget);
        expect(find.text('Alice is typing'), findsOneWidget);
      },
    );

    testWidgets('should show correct text for two typing users', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        typingUsers: [User(id: 'user1'), User(id: 'user2')],
        isDM: false,
      );
      expect(find.byType(AnimatedCircles), findsOneWidget);
      expect(find.text('Alice and Bob are typing'), findsOneWidget);
    });

    testWidgets('should show correct text for more than two typing users', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        typingUsers: [User(id: 'user1'), User(id: 'user2'), User(id: 'user3')],
        isDM: false,
      );
      expect(find.byType(AnimatedCircles), findsOneWidget);
      expect(find.text('Alice and 2 others are typing'), findsOneWidget);
    });

    testWidgets('should use correct text style', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        typingUsers: [User(id: 'user1')],
        isDM: false,
      );
      final textWidget = tester.widget<Text>(find.text('Alice is typing'));
      final theme = Theme.of(tester.element(find.text('Alice is typing')));
      expect(textWidget.style?.color, equals(theme.colorScheme.primary));
      expect(textWidget.style?.fontSize, equals(14.0));
    });

    testWidgets('should have correct padding for animated circles', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        typingUsers: [User(id: 'user1')],
        isDM: true,
      );
      // Find the Padding widget that wraps the AnimatedCircles
      final paddingFinder = find.ancestor(
        of: find.byType(AnimatedCircles),
        matching: find.byType(Padding),
      );
      expect(paddingFinder, findsOneWidget);

      final padding = tester.widget<Padding>(paddingFinder);
      expect(padding.padding, equals(const EdgeInsets.only(top: 10)));
    });
  });
}
