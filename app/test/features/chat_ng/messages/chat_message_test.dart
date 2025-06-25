import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../comments/mock_data/mock_message_content.dart';
import '../diff_applier_test.dart';

class MockTimelineEventItem extends Mock implements TimelineEventItem {
  final String mockSender;
  final MockMsgContent? mockMsgContent;
  final String? mockMsgType;
  final String mockEventType;
  final bool mockWasEdited;
  MockTimelineEventItem({
    required this.mockSender,
    this.mockMsgContent,
    this.mockMsgType,
    this.mockEventType = 'm.room.message',
    this.mockWasEdited = false,
  });
  @override
  String sender() => mockSender;

  @override
  MockMsgContent? msgContent() => mockMsgContent;

  @override
  String? msgType() => mockMsgType;

  @override
  String eventType() => mockEventType;

  @override
  bool wasEdited() => mockWasEdited;

  @override
  int originServerTs() => DateTime.now().millisecondsSinceEpoch;
}

void main() {
  group('Chat-NG messages test', () {
    group('show avatars provider tests ', () {
      final userMsgA1 = MockTimelineItem(
        id: 'A1',
        mockEventItem: MockTimelineEventItem(mockSender: 'user-1'),
      );
      final userMsgA2 = MockTimelineItem(
        id: 'A2',
        mockEventItem: MockTimelineEventItem(mockSender: 'user-1'),
      );
      final userMsgB1 = MockTimelineItem(
        id: 'B1',
        mockEventItem: MockTimelineEventItem(mockSender: 'user-2'),
      );

      final container = ProviderContainer(
        overrides: [
          renderableChatMessagesProvider.overrideWith(
            (ref, roomId) => ['A1', 'A2', 'B1'],
          ),
          chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
            final uniqueId = roomMsgId.uniqueId;
            return switch (uniqueId) {
              'A1' => userMsgA1,
              'A2' => userMsgA2,
              'B1' => userMsgB1,
              _ => null,
            };
          }),
        ],
      );

      test('shows avatar for last message in the list', () {
        final RoomMsgId query = (roomId: 'test-room', uniqueId: 'B1');
        final result = container.read(isLastMessageBySenderProvider(query));
        expect(result, true);
      });

      test('shows avatar when next message is from different user', () {
        final RoomMsgId query = (roomId: 'test-room', uniqueId: 'A2');
        final result = container.read(isLastMessageBySenderProvider(query));
        expect(result, true);
      });

      test('hides avatar when next message is from same user', () {
        final RoomMsgId query = (roomId: 'test-room', uniqueId: 'A1');
        final result = container.read(isLastMessageBySenderProvider(query));
        expect(result, true);
      });
    });
  });

  group('emoji only detection unit tests', () {
    test('single emoji returns true', () {
      expect(isOnlyEmojis('👋'), isTrue);
      expect(isOnlyEmojis('🌟'), isTrue);
      expect(isOnlyEmojis('😀'), isTrue);
    });

    test('multiple emojis return true', () {
      expect(isOnlyEmojis('👋 🌟'), isTrue);
      expect(isOnlyEmojis('😀 😃 😄'), isTrue);
      expect(isOnlyEmojis('🎉 ✨ 🎈'), isTrue);
    });

    test('emojis with whitespace return true', () {
      expect(isOnlyEmojis('   👋   '), isTrue);
      expect(isOnlyEmojis('👋\n🌟'), isTrue);
      expect(isOnlyEmojis(' 😀  😃  😄 '), isTrue);
    });

    test('mixed text and emojis return false', () {
      expect(isOnlyEmojis('Hello 👋'), isFalse);
      expect(isOnlyEmojis('Hi! 😀'), isFalse);
      expect(isOnlyEmojis('Good morning 🌞'), isFalse);
      expect(isOnlyEmojis('👋 Hello'), isFalse);
      expect(isOnlyEmojis('Hey there! 👋 🌟'), isFalse);
    });

    test('text only returns false', () {
      expect(isOnlyEmojis('Hello'), isFalse);
      expect(isOnlyEmojis('   '), isFalse);
      expect(isOnlyEmojis(''), isFalse);
      expect(isOnlyEmojis('123'), isFalse);
      expect(isOnlyEmojis('Hello World!'), isFalse);
    });

    test('special characters return false', () {
      expect(isOnlyEmojis('!@#%'), isFalse);
      expect(isOnlyEmojis('&^*`'), isFalse);
    });
  });
}
