import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event_item.dart';
import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/chat_ng/widgets/sending_state_widget.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem, MsgContent, RoomMessage, EventSendState;
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

class MockRoomEventItem extends Mock implements RoomEventItem {
  final String _eventType;
  final String _msgType;
  final String _sender;
  final MockMsgContent? _msgContent;
  final EventSendState? _sendState;

  MockRoomEventItem({
    required String eventType,
    String msgType = 'm.text',
    required String sender,
    MockMsgContent? msgContent,
    EventSendState? sendState,
  }) : _eventType = eventType,
       _msgType = msgType,
       _sender = sender,
       _msgContent = msgContent,
       _sendState = sendState;

  @override
  String eventType() => _eventType;

  @override
  String msgType() => _msgType;

  @override
  String sender() => _sender;

  @override
  MsgContent? msgContent() => _msgContent;

  @override
  EventSendState? sendState() => _sendState;

  @override
  bool wasEdited() => false;
}

class MockRoomMessage extends Mock implements RoomMessage {
  final String _id;
  final RoomEventItem? _eventItem;

  MockRoomMessage({required String id, RoomEventItem? eventItem})
    : _id = id,
      _eventItem = eventItem;

  @override
  String uniqueId() => _id;

  @override
  RoomEventItem? eventItem() => _eventItem;
}

void main() {
  group('ChatEvent Tests', () {
    late MockMsgContent mockContent;
    late MockRoomEventItem mockEventItem;
    late MockRoomMessage mockRoomMessage;

    setUp(() {
      mockContent = MockMsgContent(bodyText: 'Test message');
      mockEventItem = MockRoomEventItem(
        eventType: 'm.room.message',
        sender: 'test-user',
        msgContent: mockContent,
      );
      mockRoomMessage = MockRoomMessage(
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
          return mockRoomMessage;
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
      final unknownEventItem = MockRoomEventItem(
        eventType: 'unknown.type',
        sender: 'test-user',
      );
      final unknownMessage = MockRoomMessage(
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
        final sendingEventItem = MockRoomEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: mockSendState,
        );
        final sendingMessage = MockRoomMessage(
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
        final failedEventItem = MockRoomEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: mockSendState,
        );
        final failedMessage = MockRoomMessage(
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
        final sentEventItem = MockRoomEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: null, // No sending state indicates message was sent
        );
        final sentMessage = MockRoomMessage(
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
        final sentEventItem = MockRoomEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: null, // No sending state indicates message was sent
        );
        final sentMessage = MockRoomMessage(
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
        final sentEventItem = MockRoomEventItem(
          eventType: 'm.room.message',
          sender: 'test-user',
          msgContent: mockContent,
          sendState: null, // No sending state indicates message was sent
        );
        final sentMessage = MockRoomMessage(
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
  });
}
