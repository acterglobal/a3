import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/chat_ng/widgets/sending_state_widget.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show EventSendState, MsgContent, TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../helpers/test_util.dart';
import 'package:acter/common/providers/room_providers.dart';

class MockMsgContent extends Mock implements MsgContent {
  @override
  String body() => 'test message';
}

class MockTimelineEventItem extends Mock implements TimelineEventItem {
  final String _msgType;
  final EventSendState? _sendState;
  final int? _originServerTs;

  MockTimelineEventItem({
    required String msgType,
    EventSendState? sendState,
    int? originServerTs,
  }) : _msgType = msgType,
       _sendState = sendState,
       _originServerTs = originServerTs;

  @override
  String msgType() => _msgType;

  @override
  EventSendState? sendState() => _sendState;

  @override
  String eventType() => 'm.room.message';

  @override
  MsgContent? msgContent() => MockMsgContent();

  @override
  bool wasEdited() => false;

  @override
  String sender() => 'test-sender';

  @override
  int originServerTs() =>
      _originServerTs ?? DateTime.now().millisecondsSinceEpoch;
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

void main() {
  group('MessageEventItem SendState Tests', () {
    late List<Override> testOverrides;

    setUp(() {
      testOverrides = [
        messageReactionsProvider.overrideWith((ref, item) => []),
        isDirectChatProvider.overrideWith((ref, roomId) => false),
      ];
    });

    testWidgets('shows sending state for message being sent', (tester) async {
      final mockSendState = MockEventSendState('NotSentYet');
      final mockItem = MockTimelineEventItem(
        msgType: 'm.text',
        sendState: mockSendState,
      );

      await tester.pumpProviderWidget(
        overrides: testOverrides,
        child: MessageEventItem(
          roomId: 'room-1',
          messageId: 'msg-1',
          item: mockItem,
          isMe: true,
          canRedact: true,
          isFirstMessageBySender: true,
          isLastMessageBySender: true,
          isLastMessage: true,
          isDM: false,
        ),
      );

      expect(find.byType(SendingStateWidget), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows sent icon for last message by user', (tester) async {
      final mockItem = MockTimelineEventItem(
        msgType: 'm.text',
        sendState: null, // No sending state
      );

      await tester.pumpProviderWidget(
        overrides: testOverrides,
        child: MessageEventItem(
          roomId: 'room-1',
          messageId: 'msg-1',
          item: mockItem,
          isMe: true,
          canRedact: true,
          isFirstMessageBySender: true,
          isLastMessageBySender: true,
          isLastMessage: true,
          isDM: false,
        ),
      );

      expect(find.byType(SentStateWidget), findsOneWidget);
    });

    testWidgets('does not show sent icon for non-last message', (tester) async {
      final mockItem = MockTimelineEventItem(
        msgType: 'm.text',
        sendState: null, // No sending state
      );

      await tester.pumpProviderWidget(
        overrides: testOverrides,
        child: MessageEventItem(
          roomId: 'room-1',
          messageId: 'msg-1',
          item: mockItem,
          isMe: true,
          canRedact: true,
          isFirstMessageBySender: true,
          isLastMessageBySender: true,
          isLastMessage: false, // Not the last message
          isDM: false,
        ),
      );

      expect(find.byType(SendingStateWidget), findsNothing);
      expect(find.byType(SentStateWidget), findsNothing);
    });

    testWidgets('shows error state for failed message', (tester) async {
      final mockSendState = MockEventSendState('SendingFailed', 'Test error');
      final mockItem = MockTimelineEventItem(
        msgType: 'm.text',
        sendState: mockSendState,
      );

      await tester.pumpProviderWidget(
        overrides: testOverrides,
        child: MessageEventItem(
          roomId: 'room-1',
          messageId: 'msg-1',
          item: mockItem,
          isMe: true,
          canRedact: true,
          isFirstMessageBySender: true,
          isLastMessageBySender: true,
          isLastMessage: true,
          isDM: false,
        ),
      );

      expect(find.byType(SendingStateWidget), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('does not show sending state for messages from others', (
      tester,
    ) async {
      final mockSendState = MockEventSendState('NotSentYet');
      final mockItem = MockTimelineEventItem(
        msgType: 'm.text',
        sendState: mockSendState,
      );

      await tester.pumpProviderWidget(
        overrides: testOverrides,
        child: MessageEventItem(
          roomId: 'room-1',
          messageId: 'msg-1',
          item: mockItem,
          isMe: false, // Message from another user
          canRedact: false,
          isFirstMessageBySender: true,
          isLastMessageBySender: true,
          isLastMessage: true,
          isDM: false,
        ),
      );

      expect(find.byType(SendingStateWidget), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows sent icon for unknown state when last message', (
      tester,
    ) async {
      final mockSendState = MockEventSendState('UnknownState');
      final mockItem = MockTimelineEventItem(
        msgType: 'm.text',
        sendState: mockSendState,
      );

      await tester.pumpProviderWidget(
        overrides: testOverrides,
        child: MessageEventItem(
          roomId: 'room-1',
          messageId: 'msg-1',
          item: mockItem,
          isMe: true,
          canRedact: true,
          isFirstMessageBySender: true,
          isLastMessageBySender: true,
          isLastMessage: true,
          isDM: false,
        ),
      );

      expect(find.byType(SendingStateWidget), findsOneWidget);
      expect(find.byType(SentStateWidget), findsOneWidget);
    });
  });
}
