import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event_item.dart';
import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/chat_ng/widgets/sending_state_widget.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_chips_widget.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show
        EventSendState,
        MsgContent,
        ReactionRecord,
        TimelineEventItem,
        TimelineItem;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_util.dart';

class MockMsgContent extends Mock implements MsgContent {
  final String bodyText;
  MockMsgContent({required this.bodyText});

  @override
  String body() => bodyText;
}

class MockEventSendState extends Mock implements EventSendState {
  final String _state;
  final String? _error;

  MockEventSendState(this._state, [this._error]) {
    when(state).thenReturn(_state);
    when(error).thenReturn(_error);
    when(abort).thenAnswer((_) async => true);
  }
}

class MockTimelineEventItem extends Mock implements TimelineEventItem {
  final String _eventType;
  final String _msgType;
  final String _sender;
  final MockMsgContent? _msgContent;
  final EventSendState? _sendState;
  final int? _originServerTs;

  MockTimelineEventItem({
    required String eventType,
    String msgType = 'm.text',
    required String sender,
    MockMsgContent? msgContent,
    EventSendState? sendState,
    int? originServerTs,
  }) : _eventType = eventType,
       _msgType = msgType,
       _sender = sender,
       _msgContent = msgContent,
       _sendState = sendState,
       _originServerTs = originServerTs;

  @override
  String eventType() => _eventType;

  @override
  String msgType() => _msgType;

  @override
  String sender() => _sender;

  @override
  MsgContent? message() => _msgContent;

  @override
  EventSendState? sendState() => _sendState;

  @override
  bool wasEdited() => false;

  @override
  int originServerTs() =>
      _originServerTs ?? DateTime.now().millisecondsSinceEpoch;
}

class MockTimelineItem extends Mock implements TimelineItem {
  final String _id;
  final TimelineEventItem? _eventItem;

  MockTimelineItem({required String id, TimelineEventItem? eventItem})
    : _id = id,
      _eventItem = eventItem;

  @override
  String uniqueId() => _id;

  @override
  TimelineEventItem? eventItem() => _eventItem;
}

class MockReactionRecord extends Mock implements ReactionRecord {
  final bool _sentByMe;

  MockReactionRecord({bool sentByMe = false}) : _sentByMe = sentByMe;

  @override
  bool sentByMe() => _sentByMe;
}

void main() {
  group('ChatEvent Tests', () {
    late MockMsgContent mockContent;
    late MockTimelineEventItem mockEventItem;
    late MockTimelineItem mockTimelineItem;

    setUp(() {
      mockContent = MockMsgContent(bodyText: 'Test message');
      mockEventItem = MockTimelineEventItem(
        eventType: 'm.room.message',
        sender: 'test-user',
        msgContent: mockContent,
      );
      mockTimelineItem = MockTimelineItem(
        id: 'test-message',
        eventItem: mockEventItem,
      );
    });

    final testOverrides = [
      messageReactionsProvider.overrideWith((ref, item) => []),
      renderableChatMessagesProvider.overrideWith(
        (ref, roomId) => ['test-message'],
      ),
      chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
        if (roomMsgId.uniqueId == 'test-message') {
          return mockTimelineItem;
        }
        return null;
      }),
    ];

    testWidgets('renders MessageEventItem for m.room.message', (tester) async {
      await tester.pumpProviderWidget(
        overrides: testOverrides,
        child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
      );

      expect(find.byType(MessageEventItem), findsOneWidget);
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('passes correct properties to ChatEventItem', (tester) async {
      await tester.pumpProviderWidget(
        overrides: testOverrides,
        child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
      );

      final chatEventItem = tester.widget<ChatEventItem>(
        find.byType(ChatEventItem),
      );

      expect(chatEventItem.roomId, equals('test-room'));
      expect(chatEventItem.messageId, equals('test-message'));
      expect(chatEventItem.item, equals(mockEventItem));
    });
    testWidgets('renders unsupported message for unknown event type', (
      tester,
    ) async {
      final unknownEventItem = MockTimelineEventItem(
        eventType: 'unknown.type',
        sender: 'test-user',
      );
      final unknownMessage = MockTimelineItem(
        id: 'test-message',
        eventItem: unknownEventItem,
      );

      await tester.pumpProviderWidget(
        overrides: [
          messageReactionsProvider.overrideWith((ref, item) => []),
          renderableChatMessagesProvider.overrideWith(
            (ref, roomId) => ['test-message'],
          ),
          chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
            if (roomMsgId.uniqueId == 'test-message') {
              return unknownMessage;
            }
            return null;
          }),
        ],
        child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
      );

      expect(
        find.text('Unsupported chat event type: unknown.type'),
        findsOneWidget,
      );
    });

    group('SendState Tests', () {
      testWidgets('shows sending state for message being sent', (tester) async {
        final mockSendState = MockEventSendState('NotSentYet');
        final sendingEventItem = MockTimelineEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: mockSendState,
        );
        final sendingMessage = MockTimelineItem(
          id: 'test-message',
          eventItem: sendingEventItem,
        );

        await tester.pumpProviderWidget(
          overrides: [
            messageReactionsProvider.overrideWith((ref, item) => []),
            renderableChatMessagesProvider.overrideWith(
              (ref, roomId) => ['test-message'],
            ),
            chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
              if (roomMsgId.uniqueId == 'test-message') {
                return sendingMessage;
              }
              return null;
            }),
          ],
          child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
        );

        expect(find.byType(SendingStateWidget), findsOneWidget);
      });

      testWidgets('shows error state for failed message', (tester) async {
        final mockSendState = MockEventSendState('SendingFailed', 'Test error');
        final failedEventItem = MockTimelineEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: mockSendState,
        );
        final failedMessage = MockTimelineItem(
          id: 'test-message',
          eventItem: failedEventItem,
        );

        await tester.pumpProviderWidget(
          overrides: [
            messageReactionsProvider.overrideWith((ref, item) => []),
            renderableChatMessagesProvider.overrideWith(
              (ref, roomId) => ['test-message'],
            ),
            chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
              if (roomMsgId.uniqueId == 'test-message') {
                return failedMessage;
              }
              return null;
            }),
          ],
          child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
        );

        expect(find.byType(SendingStateWidget), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('shows sent icon if last message by this user', (
        tester,
      ) async {
        final sentEventItem = MockTimelineEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: null, // No sending state indicates message was sent
        );
        final sentMessage = MockTimelineItem(
          id: 'test-message',
          eventItem: sentEventItem,
        );

        await tester.pumpProviderWidget(
          overrides: [
            messageReactionsProvider.overrideWith((ref, item) => []),
            renderableChatMessagesProvider.overrideWith(
              (ref, roomId) => ['test-message'],
            ),
            chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
              if (roomMsgId.uniqueId == 'test-message') {
                return sentMessage;
              }
              return null;
            }),
            myUserIdStrProvider.overrideWith((ref) => 'test-user'),
          ],
          child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
        );

        expect(find.byType(SentStateWidget), findsOneWidget);
      });

      testWidgets('does not show icon if last message not by this user', (
        tester,
      ) async {
        final sentEventItem = MockTimelineEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: null, // No sending state indicates message was sent
        );
        final sentMessage = MockTimelineItem(
          id: 'test-message',
          eventItem: sentEventItem,
        );

        await tester.pumpProviderWidget(
          overrides: [
            messageReactionsProvider.overrideWith((ref, item) => []),
            renderableChatMessagesProvider.overrideWith(
              (ref, roomId) => ['test-message'],
            ),
            chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
              if (roomMsgId.uniqueId == 'test-message') {
                return sentMessage;
              }
              return null;
            }),
            myUserIdStrProvider.overrideWith((ref) => 'other-user'),
          ],
          child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
        );

        expect(find.byType(SentStateWidget), findsNothing);
      });

      testWidgets('does not show sent icon for non-last message', (
        tester,
      ) async {
        final sentEventItem = MockTimelineEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: null, // No sending state indicates message was sent
        );
        final sentMessage = MockTimelineItem(
          id: 'test-message',
          eventItem: sentEventItem,
        );

        await tester.pumpProviderWidget(
          overrides: [
            messageReactionsProvider.overrideWith((ref, item) => []),
            renderableChatMessagesProvider.overrideWith(
              (ref, roomId) => ['test-message', 'another-message'],
            ),
            chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
              if (roomMsgId.uniqueId == 'test-message') {
                return sentMessage;
              }
              return null;
            }),
          ],
          child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
        );

        expect(find.byType(SendingStateWidget), findsNothing);
        expect(find.byIcon(Icons.check), findsNothing);
      });
    });

    group('Reactions Tests', () {
      testWidgets('renders reactions when message has reactions', (
        tester,
      ) async {
        final reactions = [
          ('👍', [MockReactionRecord(), MockReactionRecord(sentByMe: true)]),
          ('❤️', [MockReactionRecord()]),
        ];

        await tester.pumpProviderWidget(
          overrides: [
            messageReactionsProvider.overrideWith((ref, item) => reactions),
            renderableChatMessagesProvider.overrideWith(
              (ref, roomId) => ['test-message'],
            ),
            chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
              if (roomMsgId.uniqueId == 'test-message') {
                return mockTimelineItem;
              }
              return null;
            }),
          ],
          child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
        );

        expect(find.byType(ReactionChipsWidget), findsOneWidget);

        // Verify reaction chips are rendered
        expect(find.text('👍'), findsOneWidget);
        expect(find.text('❤️'), findsOneWidget);

        // Verify reaction counts
        expect(find.text('2'), findsOneWidget); // Count for 👍
        expect(find.text('1'), findsNothing); // Count for ❤️ is 1, not rendered
      });

      testWidgets('does not render reactions section when no reactions', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: [
            messageReactionsProvider.overrideWith((ref, item) => []),
            renderableChatMessagesProvider.overrideWith(
              (ref, roomId) => ['test-message'],
            ),
            chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
              if (roomMsgId.uniqueId == 'test-message') {
                return mockTimelineItem;
              }
              return null;
            }),
          ],
          child: const ChatEvent(roomId: 'test-room', eventId: 'test-message'),
        );

        expect(find.byType(ReactionChipsWidget), findsNothing);
      });
    });
  });
}
