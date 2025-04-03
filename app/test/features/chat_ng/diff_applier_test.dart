import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_room_messages_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'messages/chat_message_test.dart';

class MockedTimelineItemDiff extends Mock implements TimelineItemDiff {
  final String act;
  final int? idx;
  final List<MockTimelineItem>? messages;
  final MockTimelineItem? message;

  MockedTimelineItemDiff({
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
  MockFfiListTimelineItem? values() =>
      messages != null ? MockFfiListTimelineItem(messages: messages!) : null;

  @override
  MockTimelineItem? value() => message;
}

class MockFfiListTimelineItem extends Mock implements FfiListTimelineItem {
  final List<MockTimelineItem> messages;

  MockFfiListTimelineItem({required this.messages});

  @override
  List<MockTimelineItem> toList({bool growable = false}) =>
      messages.toList(growable: growable);
}

class MockTimelineItem extends Mock implements TimelineItem {
  final String id;
  final MockTimelineEventItem? mockEventItem;

  MockTimelineItem({required this.id, this.mockEventItem});

  @override
  String uniqueId() => id;

  @override
  MockTimelineEventItem? eventItem() => mockEventItem;
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
        final mockDiff = MockedTimelineItemDiff(act: 'Reset', messages: []);
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d'],
          messages: {'d': MockTimelineItem(id: 'd')},
        );
        final messages = [
          MockTimelineItem(id: 'a'),
          MockTimelineItem(id: 'b'),
          MockTimelineItem(id: 'c'),
        ];
        final mockDiff = MockedTimelineItemDiff(
          act: 'Reset',
          messages: messages,
        );
        final newState = handleDiff(startingState, null, mockDiff);
        // reversed
        expect(newState.messageList, ['c', 'b', 'a']);
        expect(newState.messages.length, 3);
        expect(newState.messages.keys, ['a', 'b', 'c']);
      });
    });

    group('clear', () {
      test('on empty', () {
        final mockDiff = MockedTimelineItemDiff(act: 'Clear');
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
      });

      test('had values', () {
        final startingState = ChatRoomState(
          messageList: ['d'],
          messages: {'d': MockTimelineItem(id: 'd')},
        );
        final mockDiff = MockedTimelineItemDiff(act: 'Clear');
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, []);
        expect(newState.messages.length, 0);
      });
    });

    group('PopFront', () {
      test('on empty', () {
        final mockDiff = MockedTimelineItemDiff(act: 'PopFront');
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
      });

      test('removes value', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(act: 'PopFront');
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['d']);
        expect(newState.messages.length, 1);
        expect(newState.messages.keys, ['d']);
      });
    });

    group('PopBack', () {
      test('on empty', () {
        final mockDiff = MockedTimelineItemDiff(act: 'PopBack');
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
      });

      test('removes value', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(act: 'PopBack');
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['b']);
        expect(newState.messages.length, 1);
        expect(newState.messages.keys, ['b']);
      });
    });

    group('Remove', () {
      test('removes value', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b', 'e', 'f'],
          messages: {
            'b': MockTimelineItem(id: 'b'),
            'd': MockTimelineItem(id: 'd'),
            'e': MockTimelineItem(id: 'e'),
            'f': MockTimelineItem(id: 'f'),
          },
        );
        final newState = handleDiff(
          startingState,
          null,
          MockedTimelineItemDiff(act: 'Remove', idx: 0),
        );
        // reversed
        expect(newState.messageList, ['d', 'b', 'e']);
        expect(newState.messages.length, 3);
        expect(newState.messages.keys, ['b', 'd', 'e']);

        final secondNew = handleDiff(
          startingState,
          null,
          MockedTimelineItemDiff(act: 'Remove', idx: 1),
        );
        // reversed
        expect(secondNew.messageList, ['d', 'b', 'f']);
        expect(secondNew.messages.length, 3);
        expect(secondNew.messages.keys, ['b', 'd', 'f']);

        final thirdNew = handleDiff(
          startingState,
          null,
          MockedTimelineItemDiff(act: 'Remove', idx: 2),
        );
        // reversed
        expect(thirdNew.messageList, ['d', 'e', 'f']);
        expect(thirdNew.messages.length, 3);
        expect(thirdNew.messages.keys, ['d', 'e', 'f']);
      });
    });

    group('Append', () {
      test('Append values', () {
        final startingState = ChatRoomState(
          messageList: ['b', 'd', 'e', 'f'],
          messages: {
            'b': MockTimelineItem(id: 'b'),
            'd': MockTimelineItem(id: 'd'),
            'e': MockTimelineItem(id: 'e'),
            'f': MockTimelineItem(id: 'f'),
          },
        );
        final newState = handleDiff(
          startingState,
          null,
          MockedTimelineItemDiff(
            act: 'Append',
            messages: [MockTimelineItem(id: 'g'), MockTimelineItem(id: 'h')],
          ),
        );
        // reversed
        expect(newState.messageList, ['h', 'g', 'b', 'd', 'e', 'f']);
        expect(newState.messages.length, 6);
        expect(newState.messages.keys, ['b', 'd', 'e', 'f', 'g', 'h']);

        final secondState = handleDiff(
          startingState,
          null,
          MockedTimelineItemDiff(
            act: 'Append',
            messages: [MockTimelineItem(id: 'a')],
          ),
        );
        // reversed
        expect(secondState.messageList, ['a', 'b', 'd', 'e', 'f']);
        expect(secondState.messages.length, 5);
        expect(secondState.messages.keys, ['b', 'd', 'e', 'f', 'a']);
      });
    });

    group('PushBack', () {
      test('on empty', () {
        final mockDiff = MockedTimelineItemDiff(
          act: 'PushBack',
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(
          act: 'PushBack',
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(startingState, null, mockDiff);
        // reversed
        expect(newState.messageList, ['a', 'd', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a']);
      });
    });

    group('PushFront', () {
      test('on empty', () {
        final mockDiff = MockedTimelineItemDiff(
          act: 'PushFront',
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(
          act: 'PushFront',
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(startingState, null, mockDiff);
        // reversed
        expect(newState.messageList, ['d', 'b', 'a']);
        expect(newState.messages.keys, ['d', 'b', 'a']);
      });
    });

    group('Insert', () {
      test('on empty', () {
        final mockDiff = MockedTimelineItemDiff(
          act: 'Insert',
          idx: 0,
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(
          act: 'Insert',
          idx: 1,
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['d', 'a', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a']);
      });
    });

    group('Set', () {
      test('on empty', () {
        final mockDiff = MockedTimelineItemDiff(
          act: 'Set',
          idx: 0,
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'a', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'a': MockTimelineItem(id: 'a'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(
          act: 'Set',
          idx: 1,
          message: MockTimelineItem(id: 'a1'),
        );
        final newState = handleDiff(startingState, null, mockDiff);
        expect(newState.messageList, ['d', 'a1', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a1']);
      });
    });

    group('Truncate', () {
      test('on empty', () {
        final mockDiff = MockedTimelineItemDiff(act: 'Truncate', idx: 0);
        final newState = handleDiff(const ChatRoomState(), null, mockDiff);
        expect(newState.messageList, []);
        expect(newState.messages.length, 0);
      });

      test('with values', () {
        final startingState = ChatRoomState(
          messageList: ['d', 'a', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'a': MockTimelineItem(id: 'a'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        // reversed
        final mockDiff = MockedTimelineItemDiff(act: 'Truncate', idx: 2);
        final newState = handleDiff(startingState, null, mockDiff);

        expect(newState.messageList, ['d']);
        expect(newState.messages.keys, ['d']);
      });
    });
  });

  group('Diff Applier with AnimatedListState', () {
    group('reset', () {
      testWidgets('on empty', (t) async {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedTimelineItemDiff(act: 'Reset', messages: []);
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );
        expect(newState.messageList.length, 0);
        expect(newState.messages.length, 0);
        verify(() => mockAnimatedState.removeAllItems(any())).called(1);
        verify(() => mockAnimatedState.insertAllItems(any(), any())).called(1);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d'],
          messages: {'d': MockTimelineItem(id: 'd')},
        );
        final messages = [
          MockTimelineItem(id: 'a'),
          MockTimelineItem(id: 'b'),
          MockTimelineItem(id: 'c'),
        ];
        final mockDiff = MockedTimelineItemDiff(
          act: 'Reset',
          messages: messages,
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        // reversed
        expect(newState.messageList, ['c', 'b', 'a']);
        expect(newState.messages.length, 3);
        expect(newState.messages.keys, ['a', 'b', 'c']);
        verify(() => mockAnimatedState.removeAllItems(any())).called(1);
        verify(() => mockAnimatedState.insertAllItems(any(), any())).called(1);
      });
    });

    group('clear', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedTimelineItemDiff(act: 'Clear');
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );
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
          messages: {'d': MockTimelineItem(id: 'd')},
        );
        final mockDiff = MockedTimelineItemDiff(act: 'Clear');
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
        final mockDiff = MockedTimelineItemDiff(act: 'PopFront');
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );
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
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(act: 'PopFront');
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        // reversed
        expect(newState.messageList, ['d']);
        expect(newState.messages.length, 1);
        expect(newState.messages.keys, ['d']);

        final verifier = verify(
          () => mockAnimatedState.removeItem(captureAny(), any()),
        );
        verifier.called(1);
        // reversed
        expect(verifier.captured.single, 1);
      });
    });

    group('PopBack', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedTimelineItemDiff(act: 'PopBack');
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );

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
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(act: 'PopBack');
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        // reversed
        expect(newState.messageList, ['b']);
        expect(newState.messages.length, 1);
        expect(newState.messages.keys, ['b']);

        final verifier = verify(
          () => mockAnimatedState.removeItem(captureAny(), any()),
        );
        verifier.called(1);
        // reversed
        expect(verifier.captured.single, 0);
      });
    });

    group('Remove', () {
      test('removes value', () {
        MockAnimatedListState mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b', 'e', 'f'],
          messages: {
            'b': MockTimelineItem(id: 'b'),
            'd': MockTimelineItem(id: 'd'),
            'e': MockTimelineItem(id: 'e'),
            'f': MockTimelineItem(id: 'f'),
          },
        );
        final newState = handleDiff(
          startingState,
          mockAnimatedState,
          MockedTimelineItemDiff(act: 'Remove', idx: 0),
        );
        // reversed
        expect(newState.messageList, ['d', 'b', 'e']);
        expect(newState.messages.length, 3);
        expect(newState.messages.keys, ['b', 'd', 'e']);

        final verifier = verify(
          () => mockAnimatedState.removeItem(captureAny(), any()),
        );
        verifier.called(1);
        // reversed
        expect(verifier.captured.single, 3);

        mockAnimatedState = MockAnimatedListState();
        final secondNew = handleDiff(
          startingState,
          mockAnimatedState,
          MockedTimelineItemDiff(act: 'Remove', idx: 1),
        );
        // reversed
        expect(secondNew.messageList, ['d', 'b', 'f']);
        expect(secondNew.messages.length, 3);
        expect(secondNew.messages.keys, ['b', 'd', 'f']);

        final verifier2 = verify(
          () => mockAnimatedState.removeItem(captureAny(), any()),
        );
        verifier2.called(1);
        // reversed
        expect(verifier2.captured.single, 2);

        mockAnimatedState = MockAnimatedListState();

        final thirdNew = handleDiff(
          startingState,
          mockAnimatedState,
          MockedTimelineItemDiff(act: 'Remove', idx: 2),
        );
        // reversed
        expect(thirdNew.messageList, ['d', 'e', 'f']);
        expect(thirdNew.messages.length, 3);
        expect(thirdNew.messages.keys, ['d', 'e', 'f']);

        final verifier3 = verify(
          () => mockAnimatedState.removeItem(captureAny(), any()),
        );
        verifier3.called(1);
        // reversed
        expect(verifier3.captured.single, 1);
      });
    });

    group('Append', () {
      test('Append values', () {
        MockAnimatedListState mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['b', 'd', 'e', 'f'],
          messages: {
            'b': MockTimelineItem(id: 'b'),
            'd': MockTimelineItem(id: 'd'),
            'e': MockTimelineItem(id: 'e'),
            'f': MockTimelineItem(id: 'f'),
          },
        );
        final newState = handleDiff(
          startingState,
          mockAnimatedState,
          MockedTimelineItemDiff(
            act: 'Append',
            messages: [MockTimelineItem(id: 'g'), MockTimelineItem(id: 'h')],
          ),
        );
        // reversed
        expect(newState.messageList, ['h', 'g', 'b', 'd', 'e', 'f']);
        expect(newState.messages.length, 6);
        expect(newState.messages.keys, ['b', 'd', 'e', 'f', 'g', 'h']);

        final verifier1 = verify(
          () => mockAnimatedState.insertAllItems(captureAny(), captureAny()),
        );
        verifier1.called(1);
        // reversed
        expect(verifier1.captured, [0, 2]);

        mockAnimatedState = MockAnimatedListState();
        final secondState = handleDiff(
          startingState,
          mockAnimatedState,
          MockedTimelineItemDiff(
            act: 'Append',
            messages: [MockTimelineItem(id: 'a')],
          ),
        );
        expect(secondState.messageList, ['a', 'b', 'd', 'e', 'f']);
        expect(secondState.messages.length, 5);
        expect(secondState.messages.keys, ['b', 'd', 'e', 'f', 'a']);

        final verifier2 = verify(
          () => mockAnimatedState.insertAllItems(captureAny(), captureAny()),
        );
        verifier2.called(1);
        expect(verifier2.captured, [0, 1]);
      });
    });

    group('PushBack', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedTimelineItemDiff(
          act: 'PushBack',
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);

        final verifier1 = verify(
          () => mockAnimatedState.insertItem(captureAny()),
        );
        verifier1.called(1);
        expect(verifier1.captured.single, 0);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(
          act: 'PushBack',
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        // reversed
        expect(newState.messageList, ['a', 'd', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a']);

        final verifier1 = verify(
          () => mockAnimatedState.insertItem(captureAny()),
        );
        verifier1.called(1);
        // reversed
        expect(verifier1.captured.single, 0);
      });
    });

    group('PushFront', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedTimelineItemDiff(
          act: 'PushFront',
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);

        final verifier1 = verify(
          () => mockAnimatedState.insertItem(captureAny()),
        );
        verifier1.called(1);
        expect(verifier1.captured.single, 0);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(
          act: 'PushFront',
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['d', 'b', 'a']);
        expect(newState.messages.keys, ['d', 'b', 'a']);

        final verifier1 = verify(
          () => mockAnimatedState.insertItem(captureAny()),
        );
        verifier1.called(1);
        expect(verifier1.captured.single, 2);
      });
    });

    group('Insert', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedTimelineItemDiff(
          act: 'Insert',
          idx: 0,
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);

        final verifier1 = verify(
          () => mockAnimatedState.insertItem(captureAny()),
        );
        verifier1.called(1);
        expect(verifier1.captured.single, 0);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(
          act: 'Insert',
          idx: 1,
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        expect(newState.messageList, ['d', 'a', 'b']);
        expect(newState.messages.keys, ['d', 'b', 'a']);

        final verifier1 = verify(
          () => mockAnimatedState.insertItem(captureAny()),
        );
        verifier1.called(1);
        expect(verifier1.captured.single, 1);
      });
    });

    group('Set', () {
      test('on empty', () {
        final mockAnimatedState = MockAnimatedListState();
        final mockDiff = MockedTimelineItemDiff(
          act: 'Set',
          idx: 0,
          message: MockTimelineItem(id: 'a'),
        );
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );
        expect(newState.messageList, ['a']);
        expect(newState.messages.length, 1);

        final verifier1 = verify(
          () => mockAnimatedState.insertItem(captureAny()),
        );
        verifier1.called(1);
        expect(verifier1.captured, [0]);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'a', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'a': MockTimelineItem(id: 'a'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(
          act: 'Set',
          idx: 1,
          message: MockTimelineItem(id: 'a1'),
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
        final mockDiff = MockedTimelineItemDiff(act: 'Truncate', idx: 0);
        final newState = handleDiff(
          const ChatRoomState(),
          mockAnimatedState,
          mockDiff,
        );
        expect(newState.messageList, []);
        expect(newState.messages.length, 0);
      });

      test('with values', () {
        final mockAnimatedState = MockAnimatedListState();
        final startingState = ChatRoomState(
          messageList: ['d', 'a', 'b'],
          messages: {
            'd': MockTimelineItem(id: 'd'),
            'a': MockTimelineItem(id: 'a'),
            'b': MockTimelineItem(id: 'b'),
          },
        );
        final mockDiff = MockedTimelineItemDiff(act: 'Truncate', idx: 2);
        final newState = handleDiff(startingState, mockAnimatedState, mockDiff);
        // reversed
        expect(newState.messageList, ['d']);
        expect(newState.messages.keys, ['d']);

        final verifier1 = verify(
          () => mockAnimatedState.removeItem(captureAny(), any()),
        );
        verifier1.called(2);
        // reversed
        expect(verifier1.captured, [1, 2]);
      });
    });
  });
}
