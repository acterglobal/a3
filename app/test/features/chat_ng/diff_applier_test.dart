import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_room_messages_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'messages/chat_message_test.dart';

class MockedRoomMessageDiff extends Mock implements RoomMessageDiff {
  final String act;
  final int? idx;
  final List<MockRoomMessage>? messages;
  final MockRoomMessage? message;

  MockedRoomMessageDiff({
    required this.act,
    this.idx,
    this.messages,
    this.message,
  });

  @override
  int? index() => idx;

  @override
  String action() => act;

  @override
  MockFfiListRoomMessage? values() =>
      messages != null ? MockFfiListRoomMessage(messages: messages!) : null;

  @override
  MockRoomMessage? value() => message;
}

class MockFfiListRoomMessage extends Mock implements FfiListRoomMessage {
  final List<MockRoomMessage> messages;

  MockFfiListRoomMessage({required this.messages});

  @override
  List<MockRoomMessage> toList({bool growable = false}) =>
      messages.toList(growable: growable);
}

class MockRoomMessage extends Mock implements RoomMessage {
  final String id;
  final MockRoomEventItem? mockEventItem;

  MockRoomMessage({required this.id, this.mockEventItem});

  @override
  String uniqueId() => id;

  @override
  MockRoomEventItem? eventItem() => mockEventItem;
}

class MockAnimatedListState extends Mock implements AnimatedListState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) =>
      super.toString();
}

void main() {
  group('Diff Applier', () {
    group('reset', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'Reset',
          messages: [],
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
          },
        );
        final messages = [
          MockRoomMessage(id: 'a'),
          MockRoomMessage(id: 'b'),
          MockRoomMessage(id: 'c'),
        ];
        final mockDiff = MockedRoomMessageDiff(
          act: 'Reset',
          messages: messages,
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['a', 'b', 'c']);
        expect(newState.messages.length, 3);
        expect(newState.messages.keys, ['a', 'b', 'c']);
      });
    });

    group('clear', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'Clear',
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
      });

      test('had values', () {
        final startingState = ChatRoomState(
          messageList: ['d'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'Clear',
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, []);
        expect(newState.messages.length, 0);
      });
    });

    group('PopFront', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'PopFront',
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
      });

      test('removes value', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'PopFront',
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['b']);
        expect(newState.messages.length, 1);
        expect(newState.messages.keys, ['b']);
      });
    });

    group('PopBack', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'PopBack',
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
      });

      test('removes value', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'PopBack',
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['d']);
        expect(newState.messages.length, 1);
        expect(newState.messages.keys, ['d']);
      });
    });

    group('Remove', () {
      test('removes value', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b', 'e', 'f'],
          messages: {
            'b': MockRoomMessage(id: 'b'),
            'd': MockRoomMessage(id: 'd'),
            'e': MockRoomMessage(id: 'e'),
            'f': MockRoomMessage(id: 'f'),
          },
        );
        final newState = handleDiff(
          startingState,
          null,
          MockedRoomMessageDiff(
            act: 'Remove',
            idx: 0,
          ),
        );
        expect(newState.messageList, ['b', 'e', 'f']);
        expect(newState.messages.length, 3);
        expect(newState.messages.keys, ['b', 'e', 'f']);

        final secondNew = handleDiff(
          startingState,
          null,
          MockedRoomMessageDiff(
            act: 'Remove',
            idx: 1,
          ),
        );
        expect(secondNew.messageList, ['d', 'e', 'f']);
        expect(secondNew.messages.length, 3);
        expect(secondNew.messages.keys, ['d', 'e', 'f']);

        final thirdNew = handleDiff(
          startingState,
          null,
          MockedRoomMessageDiff(
            act: 'Remove',
            idx: 2,
          ),
        );
        expect(thirdNew.messageList, ['d', 'b', 'f']);
        expect(thirdNew.messages.length, 3);
        expect(thirdNew.messages.keys, ['b', 'd', 'f']);
      });
    });

    group('Append', () {
      test('Append values', () {
        final startingState = ChatRoomState(
          messageList: ['b', 'd', 'e', 'f'],
          messages: {
            'b': MockRoomMessage(id: 'b'),
            'd': MockRoomMessage(id: 'd'),
            'e': MockRoomMessage(id: 'e'),
            'f': MockRoomMessage(id: 'f'),
          },
        );
        final newState = handleDiff(
          startingState,
          null,
          MockedRoomMessageDiff(
            act: 'Append',
            messages: [
              MockRoomMessage(id: 'g'),
              MockRoomMessage(id: 'h'),
            ],
          ),
        );
        expect(newState.messageList, ['b', 'd', 'e', 'f', 'g', 'h']);
        expect(newState.messages.length, 6);
        expect(newState.messages.keys, ['b', 'd', 'e', 'f', 'g', 'h']);

        final secondState = handleDiff(
          startingState,
          null,
          MockedRoomMessageDiff(
            act: 'Append',
            messages: [
              MockRoomMessage(id: 'a'),
            ],
          ),
        );
        expect(secondState.messageList, ['b', 'd', 'e', 'f', 'a']);
        expect(secondState.messages.length, 5);
        expect(secondState.messages.keys, ['b', 'd', 'e', 'f', 'a']);
      });
    });

    group('PushBack', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'PushBack',
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'PushBack',
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['d', 'b', 'a']);
        expect(newState.messages.keys, ['d', 'b', 'a']);
      });
    });

    group('PushFront', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'PushFront',
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'PushFront',
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['a', 'd', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a']);
      });
    });

    group('Insert', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'Insert',
          idx: 0,
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'Insert',
          idx: 1,
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['d', 'a', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a']);
      });
    });

    group('Set', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'Set',
          idx: 0,
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'a', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'a': MockRoomMessage(id: 'a'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'Set',
          idx: 1,
          message: MockRoomMessage(id: 'a1'),
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['d', 'a1', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a1']);
      });
    });

    group('Truncate', () {
      test('on empty', () {
        final mockDiff = MockedRoomMessageDiff(
          act: 'Truncate',
          idx: 0,
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, []);
        expect(newState.messages.length, 0);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'a', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'a': MockRoomMessage(id: 'a'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'Truncate',
          idx: 1,
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, [
          'd',
        ]);
        expect(newState.messages.keys, ['d']);
      });
    });
  });

  group('Diff Applier with AnimatedListState', () {
    group('reset', () {
      testWidgets('on empty', (t) async {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'Reset',
          messages: [],
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
        verify(() => mockAnimatedState.removeAllItems(any())).called(1);
        verify(() => mockAnimatedState.insertAllItems(any(), any())).called(1);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
          },
        );
        final messages = [
          MockRoomMessage(id: 'a'),
          MockRoomMessage(id: 'b'),
          MockRoomMessage(id: 'c'),
        ];
        final mockDiff = MockedRoomMessageDiff(
          act: 'Reset',
          messages: messages,
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['a', 'b', 'c']);
        expect(newState.messages.length, 3);
        expect(newState.messages.keys, ['a', 'b', 'c']);
        verify(() => mockAnimatedState.removeAllItems(any())).called(1);
        verify(() => mockAnimatedState.insertAllItems(any(), any())).called(1);
      });
    });

    group('clear', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'Clear',
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);

        // nothing to remove
        verifyNever(() => mockAnimatedState.removeAllItems(any()));
        verifyNever(() => mockAnimatedState.insertAllItems(any(), any()));
      });

      test('had values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'Clear',
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, []);
        expect(newState.messages.length, 0);
        verify(() => mockAnimatedState.removeAllItems(any())).called(1);
        verifyNever(() => mockAnimatedState.insertAllItems(any(), any()));
      });
    });

    group('PopFront', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'PopFront',
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);

        // nothing to remove
        verifyNever(() => mockAnimatedState.removeItem(captureAny(), any()));
      });

      test('removes value', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'PopFront',
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['b']);
        expect(newState.messages.length, 1);
        expect(newState.messages.keys, ['b']);

        final verifier =
            verify(() => mockAnimatedState.removeItem(captureAny(), any()));
        verifier.called(1);
        expect(verifier.captured.single, 0);
      });
    });

    group('PopBack', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'PopBack',
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);

        // nothing to remove
        verifyNever(() => mockAnimatedState.removeItem(captureAny(), any()));
      });

      test('removes value', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'PopBack',
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['d']);
        expect(newState.messages.length, 1);
        expect(newState.messages.keys, ['d']);

        final verifier =
            verify(() => mockAnimatedState.removeItem(captureAny(), any()));
        verifier.called(1);
        expect(verifier.captured.single, 1);
      });
    });

    group('Remove', () {
      test('removes value', () {
        MockAnimatedListState mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b', 'e', 'f'],
          messages: {
            'b': MockRoomMessage(id: 'b'),
            'd': MockRoomMessage(id: 'd'),
            'e': MockRoomMessage(id: 'e'),
            'f': MockRoomMessage(id: 'f'),
          },
        );
        final newState = handleDiff(
          startingState,
          mockAnimatedState,
          MockedRoomMessageDiff(
            act: 'Remove',
            idx: 0,
          ),
        );
        expect(newState.messageList, ['b', 'e', 'f']);
        expect(newState.messages.length, 3);
        expect(newState.messages.keys, ['b', 'e', 'f']);

        final verifier =
            verify(() => mockAnimatedState.removeItem(captureAny(), any()));
        verifier.called(1);
        expect(verifier.captured.single, 0);

        mockAnimatedState = MockAnimatedListState();
        final secondNew = handleDiff(
          startingState,
          mockAnimatedState,
          MockedRoomMessageDiff(
            act: 'Remove',
            idx: 1,
          ),
        );
        expect(secondNew.messageList, ['d', 'e', 'f']);
        expect(secondNew.messages.length, 3);
        expect(secondNew.messages.keys, ['d', 'e', 'f']);

        final verifier2 =
            verify(() => mockAnimatedState.removeItem(captureAny(), any()));
        verifier2.called(1);
        expect(verifier2.captured.single, 1);

        mockAnimatedState = MockAnimatedListState();

        final thirdNew = handleDiff(
          startingState,
          mockAnimatedState,
          MockedRoomMessageDiff(
            act: 'Remove',
            idx: 2,
          ),
        );
        expect(thirdNew.messageList, ['d', 'b', 'f']);
        expect(thirdNew.messages.length, 3);
        expect(thirdNew.messages.keys, ['b', 'd', 'f']);

        final verifier3 =
            verify(() => mockAnimatedState.removeItem(captureAny(), any()));
        verifier3.called(1);
        expect(verifier3.captured.single, 2);
      });
    });

    group('Append', () {
      test('Append values', () {
        MockAnimatedListState mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['b', 'd', 'e', 'f'],
          messages: {
            'b': MockRoomMessage(id: 'b'),
            'd': MockRoomMessage(id: 'd'),
            'e': MockRoomMessage(id: 'e'),
            'f': MockRoomMessage(id: 'f'),
          },
        );
        final newState = handleDiff(
          startingState,
          mockAnimatedState,
          MockedRoomMessageDiff(
            act: 'Append',
            messages: [
              MockRoomMessage(id: 'g'),
              MockRoomMessage(id: 'h'),
            ],
          ),
        );
        expect(newState.messageList, ['b', 'd', 'e', 'f', 'g', 'h']);
        expect(newState.messages.length, 6);
        expect(newState.messages.keys, ['b', 'd', 'e', 'f', 'g', 'h']);

        final verifier1 = verify(
          () => mockAnimatedState.insertAllItems(captureAny(), captureAny()),
        );
        verifier1.called(1);
        expect(verifier1.captured, [4, 2]);

        mockAnimatedState = MockAnimatedListState();
        final secondState = handleDiff(
          startingState,
          mockAnimatedState,
          MockedRoomMessageDiff(
            act: 'Append',
            messages: [
              MockRoomMessage(id: 'a'),
            ],
          ),
        );
        expect(secondState.messageList, ['b', 'd', 'e', 'f', 'a']);
        expect(secondState.messages.length, 5);
        expect(secondState.messages.keys, ['b', 'd', 'e', 'f', 'a']);

        final verifier2 = verify(
          () => mockAnimatedState.insertAllItems(captureAny(), captureAny()),
        );
        verifier2.called(1);
        expect(verifier2.captured, [4, 1]);
      });
    });

    group('PushBack', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'PushBack',
          message: MockRoomMessage(id: 'a'),
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);

        final verifier1 =
            verify(() => mockAnimatedState.insertItem(captureAny()));
        verifier1.called(1);
        expect(verifier1.captured.single, 0);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'PushBack',
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['d', 'b', 'a']);
        expect(newState.messages.keys, ['d', 'b', 'a']);

        final verifier1 =
            verify(() => mockAnimatedState.insertItem(captureAny()));
        verifier1.called(1);
        expect(verifier1.captured.single, 2);
      });
    });

    group('PushFront', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'PushFront',
          message: MockRoomMessage(id: 'a'),
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);

        final verifier1 =
            verify(() => mockAnimatedState.insertItem(captureAny()));
        verifier1.called(1);
        expect(verifier1.captured.single, 0);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'PushFront',
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['a', 'd', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a']);

        final verifier1 =
            verify(() => mockAnimatedState.insertItem(captureAny()));
        verifier1.called(1);
        expect(verifier1.captured.single, 0);
      });
    });

    group('Insert', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'Insert',
          idx: 0,
          message: MockRoomMessage(id: 'a'),
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);

        final verifier1 =
            verify(() => mockAnimatedState.insertItem(captureAny()));
        verifier1.called(1);
        expect(verifier1.captured.single, 0);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'Insert',
          idx: 1,
          message: MockRoomMessage(id: 'a'),
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['d', 'a', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a']);

        final verifier1 =
            verify(() => mockAnimatedState.insertItem(captureAny()));
        verifier1.called(1);
        expect(verifier1.captured.single, 1);
      });
    });

    group('Set', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'Set',
          idx: 0,
          message: MockRoomMessage(id: 'a'),
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);

        final verifier1 =
            verify(() => mockAnimatedState.insertItem(captureAny()));
        verifier1.called(1);
        expect(verifier1.captured, [0]);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'a', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'a': MockRoomMessage(id: 'a'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'Set',
          idx: 1,
          message: MockRoomMessage(id: 'a1'),
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['d', 'a1', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a1']);

        verifyNever(() => mockAnimatedState.insertItem(any()));
        verifyNever(() => mockAnimatedState.removeItem(any(), any()));
      });
    });

    group('Truncate', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedRoomMessageDiff(
          act: 'Truncate',
          idx: 0,
        );
        final newState =
            handleDiff(const ChatRoomState(), mockAnimatedState, mockDiff);
        expect(newState.messageList, []);
        expect(newState.messages.length, 0);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'a', 'b'],
          messages: {
            'd': MockRoomMessage(id: 'd'),
            'a': MockRoomMessage(id: 'a'),
            'b': MockRoomMessage(id: 'b'),
          },
        );
        final mockDiff = MockedRoomMessageDiff(
          act: 'Truncate',
          idx: 1,
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, [
          'd',
        ]);
        expect(newState.messages.keys, ['d']);

        final verifier1 =
            verify(() => mockAnimatedState.removeItem(captureAny(), any()));
        verifier1.called(2);
        expect(verifier1.captured, [2, 1]);
      });
    });
  });
}
