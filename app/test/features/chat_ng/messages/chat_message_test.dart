import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../diff_applier_test.dart';

class MockRoomEventItem extends Mock implements RoomEventItem {
  final String mockSender;

  MockRoomEventItem({required this.mockSender});
  @override
  String sender() => mockSender;
}

void main() {
  group('Chat-NG messages test', () {
    group('show avatars provider tests ', () {
      final userMsgA1 = MockRoomMessage(
        id: 'A1',
        mockEventItem: MockRoomEventItem(mockSender: 'user-1'),
      );
      final userMsgA2 = MockRoomMessage(
        id: 'A2',
        mockEventItem: MockRoomEventItem(mockSender: 'user-1'),
      );
      final userMsgB1 = MockRoomMessage(
        id: 'B1',
        mockEventItem: MockRoomEventItem(mockSender: 'user-2'),
      );

      final container = ProviderContainer(
        overrides: [
          renderableChatMessagesProvider
              .overrideWith((ref, roomId) => ['A1', 'A2', 'B1']),
          chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
            final uniqueId = roomMsgId.$2;
            switch (uniqueId) {
              case 'A1':
                return userMsgA1;
              case 'A2':
                return userMsgA2;
              case 'B1':
                return userMsgB1;
              default:
                return null;
            }
          }),
        ],
      );

      test('shows avatar for last message in the list', () {
        final RoomMsgId query = ('test-room', 'B1');
        final result = container.read(shouldShowAvatarProvider(query));
        expect(result, true);
      });

      test('shows avatar when next message is from different user', () {
        final RoomMsgId query = ('test-room', 'A2');
        final result = container.read(shouldShowAvatarProvider(query));
        expect(result, true);
      });

      test('hides avatar when next message is from same user', () {
        final RoomMsgId query = ('test-room', 'A1');
        final result = container.read(shouldShowAvatarProvider(query));
        expect(result, false);
      });
    });
  });
}
