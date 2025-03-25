import 'package:acter/features/chat/providers/chat_providers.dart' as chat;
import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_room_messages_notifier.dart';
import 'package:acter/features/chat_ng/widgets/chat_messages.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_util.dart';

class MockTimelineStream extends Mock implements TimelineStream {
  @override
  Future<bool> paginateBackwards(int count) async => false;
}

class MockRef extends Mock implements Ref {}

class MockChatRoomMessagesNotifier extends Mock
    implements ChatRoomMessagesNotifier {
  final ChatRoomState initalState;
  final bool useDefaultListener;

  MockChatRoomMessagesNotifier(
    this.initalState, {
    this.useDefaultListener = true,
  });

  @override
  ChatRoomState get state => initalState;

  @override
  void Function() addListener(
    void Function(ChatRoomState) listener, {
    bool fireImmediately = true,
  }) {
    if (useDefaultListener) {
      if (fireImmediately) {
        listener(state);
      }
      return () {};
    }
    return super.noSuchMethod(
          Invocation.method(
            #addListener,
            [listener],
            {#fireImmediately: fireImmediately},
          ),
        )
        as void Function();
  }
}

void main() {
  group('ChatMessages Widget Tests', () {
    final testRoomId = 'test-room-id';

    testWidgets('renders empty state correctly', (tester) async {
      final emptyState = ChatRoomState(
        messageList: [],
        loading: const ChatRoomLoadingState.initial(),
      );

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(
            testRoomId,
          ).overrideWith((ref) => MockChatRoomMessagesNotifier(emptyState)),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(MockTimelineStream())),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
          isActiveProvider(LabsFeature.chatUnread).overrideWith((ref) => false),
          chat.hasUnreadMessages(testRoomId).overrideWith((ref) => false),
        ],
        child: ChatMessages(roomId: testRoomId),
      );

      await tester.pump();

      // Now check for the list
      expect(find.byType(AnimatedList), findsOneWidget);

      expect(find.byType(ChatEvent), findsNothing);
    });

    testWidgets('renders messages correctly when available', (tester) async {
      final messagesState = ChatRoomState(
        messageList: List.generate(5, (index) => 'msg$index'),
        loading: const ChatRoomLoadingState.loaded(),
      );

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(
            testRoomId,
          ).overrideWith((ref) => MockChatRoomMessagesNotifier(messagesState)),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(MockTimelineStream())),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
          isActiveProvider(LabsFeature.chatUnread).overrideWith((ref) => false),
        ],
        child: ChatMessages(roomId: testRoomId),
      );

      await tester.pump();

      expect(find.byType(AnimatedList), findsOneWidget);

      //  verify the list has the correct number of items
      final animatedList = tester.widget<AnimatedList>(
        find.byType(AnimatedList),
      );
      expect(animatedList.initialItemCount, equals(5));
    });

    testWidgets('shows loading indicator and hides it when done loading', (
      tester,
    ) async {
      final notifier = ChatRoomMessagesNotifier(
        roomId: testRoomId,
        ref: MockRef(),
      );

      // initialize with loading state
      notifier.state = ChatRoomState(
        messageList: ['msg1', 'msg2'],
        loading: const ChatRoomLoadingState.loading(),
      );

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(testRoomId).overrideWith((ref) => notifier),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(MockTimelineStream())),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
        ],
        child: ChatMessages(roomId: testRoomId),
      );

      // verify indicator is shown when loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // update state to loaded
      notifier.state = notifier.state.copyWith(
        loading: const ChatRoomLoadingState.loaded(),
      );

      await tester.pump();
      //   verify indicator is hidden when loaded
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('marks messages as read when scrolling to bottom', (
      tester,
    ) async {
      final messagesState = ChatRoomState(
        messageList: List.generate(20, (index) => 'msg$index'),
        loading: const ChatRoomLoadingState.loaded(),
      );

      final mockTimelineStream = MockTimelineStream();
      when(
        () => mockTimelineStream.markAsRead(any()),
      ).thenAnswer((_) async => false);

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(
            testRoomId,
          ).overrideWith((ref) => MockChatRoomMessagesNotifier(messagesState)),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(mockTimelineStream)),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
          isActiveProvider(LabsFeature.chatUnread).overrideWith((ref) => false),
          chat.hasUnreadMessages(testRoomId).overrideWith((ref) => true),
        ],
        child: ChatMessages(roomId: testRoomId),
      );

      final chatMessagesWidget = find.byType(ChatMessages);
      final state =
          tester.state(chatMessagesWidget) as ChatMessagesConsumerState;

      await state.onScroll();

      await tester.pump(const Duration(milliseconds: 300));

      // verifymarkAsRead was called
      verify(() => mockTimelineStream.markAsRead(true)).called(1);
    });

    testWidgets('handles message insertion animation correctly', (
      tester,
    ) async {
      final initialState = ChatRoomState(
        messageList: List.generate(3, (index) => 'msg$index'),
        loading: const ChatRoomLoadingState.loaded(),
      );

      final notifier = ChatRoomMessagesNotifier(
        roomId: testRoomId,
        ref: MockRef(),
      );
      notifier.state = initialState;

      final animatedListKey = GlobalKey<AnimatedListState>();

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(testRoomId).overrideWith((ref) => notifier),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(MockTimelineStream())),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => animatedListKey),
        ],
        child: ChatMessages(roomId: testRoomId),
      );

      expect(animatedListKey.currentState?.widget.initialItemCount, equals(3));

      // verify initial message order
      expect(notifier.state.messageList, equals(['msg0', 'msg1', 'msg2']));

      // add new message
      final updatedState = initialState.copyWith(
        messageList: [...initialState.messageList, 'newMessage'],
      );
      notifier.state = updatedState;

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // verify the list was updated
      expect(animatedListKey.currentState?.widget.initialItemCount, equals(4));

      // Verify final message order
      expect(
        notifier.state.messageList,
        equals(['msg0', 'msg1', 'msg2', 'newMessage']),
      );
    });

    testWidgets('scroll to end animates to the bottom of the list', (
      WidgetTester tester,
    ) async {
      final messagesState = ChatRoomState(
        messageList: List.generate(20, (index) => 'msg$index'),
        loading: const ChatRoomLoadingState.loaded(),
      );

      final notifier = ChatRoomMessagesNotifier(
        roomId: testRoomId,
        ref: MockRef(),
      );
      notifier.state = messagesState;

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(testRoomId).overrideWith((ref) => notifier),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(MockTimelineStream())),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: ChatMessages(roomId: testRoomId),
            ),
          ),
        ),
      );

      final scrollController =
          tester.widget<AnimatedList>(find.byType(AnimatedList)).controller;

      // scroll up
      scrollController?.position.jumpTo(100.0);
      await tester.pump();

      final fabFinder = find.byKey(ChatMessages.fabScrollToBottomKey);
      expect(fabFinder, findsOneWidget);

      // button is visible (opacity should be 1)
      final opacityWidget = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacityWidget.opacity, equals(1.0));

      final buttonFinder = find.descendant(
        of: fabFinder,
        matching: find.byType(FloatingActionButton),
      );

      expect(buttonFinder, findsOneWidget);

      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle(Durations.medium3);

      expect(
        scrollController?.position.pixels,
        equals(scrollController!.position.minScrollExtent),
      );

      // verify button is hidden (opacity should be 0)
      final updatedOpacityWidget = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(updatedOpacityWidget.opacity, equals(0.0));
    });

    testWidgets('handles message removal correctly', (tester) async {
      final initialMessages = List.generate(5, (index) => 'msg$index');

      final notifier = ChatRoomMessagesNotifier(
        roomId: testRoomId,
        ref: MockRef(),
      );

      notifier.state = ChatRoomState(
        messageList: initialMessages,
        loading: const ChatRoomLoadingState.loaded(),
      );

      final animatedListKey = GlobalKey<AnimatedListState>();

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(testRoomId).overrideWith((ref) => notifier),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(MockTimelineStream())),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => animatedListKey),
        ],
        child: MaterialApp(
          home: Scaffold(body: ChatMessages(roomId: testRoomId)),
        ),
      );

      await tester.pump();

      // initial message count
      expect(notifier.state.messageList.length, equals(5));

      final animatedList = tester.widget<AnimatedList>(
        find.byType(AnimatedList),
      );
      expect(animatedList.initialItemCount, equals(5));

      // Remove a message
      final updatedMessages = List<String>.from(initialMessages)..removeAt(2);
      notifier.state = notifier.state.copyWith(messageList: updatedMessages);

      await tester.pump();
      await tester.pumpAndSettle();

      // final message count
      expect(notifier.state.messageList.length, equals(4));
      expect(
        notifier.state.messageList,
        equals(['msg0', 'msg1', 'msg3', 'msg4']),
      );
    });
  });
}
