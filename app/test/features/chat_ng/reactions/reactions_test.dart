import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_chips_widget.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_detail_sheet.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reactions_list.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ReactionRecord, UserId;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../common/mock_data/mock_user_id.dart';
import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/test_util.dart';
import '../messages/chat_message_test.dart';

class MockReactionRecord extends Mock implements ReactionRecord {
  final UserId _senderId;

  MockReactionRecord(this._senderId);

  @override
  bool sentByMe() => false;
  @override
  UserId senderId() => _senderId;
}

void main() {
  group('Reactions widgets test', () {
    group('tab initialization tests', () {
      testWidgets('creates correct number of initial tabs', (tester) async {
        final reactions = [
          ('👍', [MockReactionRecord(createMockUserId('user-1'))]),
          (
            '❤️',
            [
              MockReactionRecord(createMockUserId('user-2')),
              MockReactionRecord(createMockUserId('user-3')),
            ]
          ),
        ];

        await tester.pumpProviderWidget(
          overrides: [
            memberAvatarInfoProvider.overrideWith(
              (ref, param) => MockAvatarInfo(uniqueId: param.userId),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReactionDetailsSheet(
                roomId: 'test-room',
                reactions: reactions,
              ),
            ),
          ),
        );

        // Verify "All" tab plus one per reaction
        expect(find.byType(Tab), findsNWidgets(3));
        expect(find.text('All 3'), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // 👍 count
        expect(find.text('2'), findsOneWidget); // ❤️ count
      });

      testWidgets('handles empty reactions list', (tester) async {
        await tester.pumpProviderWidget(
          child: MaterialApp(
            home: Scaffold(
              body: ReactionDetailsSheet(
                roomId: 'test-room',
                reactions: [],
              ),
            ),
          ),
        );

        expect(find.byType(Tab), findsNWidgets(1)); // Only "All" tab
        expect(find.text('All 0'), findsOneWidget);
      });
    });

    group('reaction update tests', () {
      final mockEvent = MockRoomEventItem(mockSender: 'user-1');
      final reactionsNotifier = StateController<List<ReactionItem>>([
        ('👍', [MockReactionRecord(createMockUserId('user-1'))]),
      ]);
      final overrides = [
        sdkProvider.overrideWith((ref) => MockActerSdk()),
        memberAvatarInfoProvider.overrideWith(
          (ref, param) => MockAvatarInfo(uniqueId: param.userId),
        ),
        messageReactionsProvider(mockEvent).overrideWith(
          (ref) => reactionsNotifier.state,
        ),
      ];
      // Helper to open bottom sheet
      Future<void> openReactionsDetailSheet(
        List<ReactionItem> reactions,
        WidgetTester tester,
      ) async {
        await tester.tap(find.byType(ReactionChipsWidget));
        await tester.pumpAndSettle();

        // Show bottom sheet directly
        await tester.pump();
        showModalBottomSheet(
          context: tester.element(find.byType(ReactionsList)),
          builder: (context) => ReactionDetailsSheet(
            roomId: 'test-room',
            reactions: reactions,
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('updates tabs when reactions change', (tester) async {
        await tester.pumpProviderWidget(
          overrides: overrides,
          child: MaterialApp(
            home: Scaffold(
              body: ReactionsList(
                roomId: 'test-room',
                messageId: 'message-1',
                item: mockEvent,
              ),
            ),
          ),
        );

        // First time opening with initial state
        await openReactionsDetailSheet(reactionsNotifier.state, tester);
        expect(find.byType(Tab), findsNWidgets(2));
        expect(find.text('All 1'), findsOneWidget);

        // Close  sheet
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        // Update reactions
        final updatedReactions = [
          ('👍', [MockReactionRecord(createMockUserId('user-1'))]),
          ('❤️', [MockReactionRecord(createMockUserId('user-2'))]),
        ];
        reactionsNotifier.state = updatedReactions;
        await tester.pumpAndSettle();

        // Open bottom sheet again with updated state
        await openReactionsDetailSheet(reactionsNotifier.state, tester);
        expect(
          find.byType(Tab),
          findsNWidgets(3),
          reason: 'Should have 3 tabs after adding a new reaction',
        );
        expect(
          find.text('All 2'),
          findsOneWidget,
          reason: 'Should show total of 2 reactions',
        );
      });

      testWidgets('updates when reaction count changes', (tester) async {
        // reset notifier state before previous test run
        reactionsNotifier.state = [
          ('👍', [MockReactionRecord(createMockUserId('user-1'))]),
        ];
        await tester.pumpProviderWidget(
          overrides: overrides,
          child: MaterialApp(
            home: Scaffold(
              body: ReactionsList(
                roomId: 'test-room',
                messageId: 'message-1',
                item: mockEvent,
              ),
            ),
          ),
        );

        // Show initial state
        await openReactionsDetailSheet(reactionsNotifier.state, tester);
        expect(find.text('1'), findsOneWidget);

        // Close bottom sheet
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        // Update state with second user
        reactionsNotifier.state = [
          (
            '👍',
            [
              MockReactionRecord(createMockUserId('user-1')),
              MockReactionRecord(createMockUserId('user-2')),
            ]
          ),
        ];
        await tester.pumpAndSettle();

        // Show updated state
        await openReactionsDetailSheet(reactionsNotifier.state, tester);
        expect(find.text('2'), findsOneWidget);
      });
    });

    group('user list tests', () {
      testWidgets('displays correct users count in each tab', (tester) async {
        final reactions = [
          (
            '👍',
            [
              MockReactionRecord(createMockUserId('user-1')),
              MockReactionRecord(createMockUserId('user-2')),
            ]
          ),
          (
            '❤️',
            [
              MockReactionRecord(createMockUserId('user-2')),
              MockReactionRecord(createMockUserId('user-3')),
            ]
          ),
        ];

        await tester.pumpProviderWidget(
          overrides: [
            memberAvatarInfoProvider.overrideWith(
              (ref, param) => MockAvatarInfo(uniqueId: param.userId),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReactionDetailsSheet(
                roomId: 'test-room',
                reactions: reactions,
              ),
            ),
          ),
        );

        // Check "All" tab content
        expect(
          find.byType(ReactionUserItem),
          findsNWidgets(3),
        ); // All unique users

        // Check 👍 tab
        await tester.tap(find.text('2').first); // First tab with count 2
        await tester.pumpAndSettle();

        expect(find.byType(ReactionUserItem), findsNWidgets(2));

        // Check ❤️ tab
        await tester.tap(find.text('2').last); // Second tab with count 2
        await tester.pumpAndSettle();
        expect(find.byType(ReactionUserItem), findsNWidgets(2));
      });
    });
  });
}
