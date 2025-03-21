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
// import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  MockChatRoomMessagesNotifier(this.initalState);

  @override
  ChatRoomState get state => initalState;

  @override
  void Function() addListener(
    void Function(ChatRoomState) listener, {
    bool fireImmediately = true,
  }) {
    if (fireImmediately) {
      listener(state);
    }
    return () {};
  }

  @override
  Future<void> loadMore({bool failOnError = true}) async {}
}

void main() {
  group('ChatMessages Widget Tests', () {
    final testRoomId = 'test-room-id';

    setUp(() {
      registerFallbackValue(const ChatRoomState());
      registerFallbackValue(true); // Register fallback for boolean parameters
      registerFallbackValue(false); // Register fallback for boolean parameters
    });

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

    testWidgets('shows loading indicator when loading', (tester) async {
      final loadingState = ChatRoomState(
        messageList: ['msg1', 'msg2'],
        loading: const ChatRoomLoadingState.loading(),
      );

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(
            testRoomId,
          ).overrideWith((ref) => MockChatRoomMessagesNotifier(loadingState)),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(MockTimelineStream())),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
        ],
        child: ChatMessages(roomId: testRoomId),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides loading indicator when not loading', (tester) async {
      final loadedState = ChatRoomState(
        messageList: ['msg1', 'msg2'],
        loading: const ChatRoomLoadingState.loaded(),
      );

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(
            testRoomId,
          ).overrideWith((ref) => MockChatRoomMessagesNotifier(loadedState)),
          chat
              .timelineStreamProvider(testRoomId)
              .overrideWith((ref) => Future.value(MockTimelineStream())),
          animatedListChatMessagesProvider(
            testRoomId,
          ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
        ],
        child: ChatMessages(roomId: testRoomId),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('handles message insertion animation correctly', (
      tester,
    ) async {
      final initialState = ChatRoomState(
        messageList: List.generate(3, (index) => 'msg$index'),
        loading: const ChatRoomLoadingState.loaded(),
      );

      // Create a real notifier that we can update
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

      // Verify initial message order
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
        ],
        child: ChatMessages(roomId: testRoomId),
      );

      final scrollController =
          tester.widget<AnimatedList>(find.byType(AnimatedList)).controller;
      final chatMessagesWidget = find.byType(ChatMessages);

      // scroll up to make the button visible
      scrollController?.position.jumpTo(100.0);

      await tester.pump();

      final initialState =
          tester.state(chatMessagesWidget) as ConsumerState<ChatMessages>;
      expect((initialState as dynamic).showScrollToBottom, isTrue);

      final finalState =
          tester.state(chatMessagesWidget) as ConsumerState<ChatMessages>;

      await (finalState as dynamic).scrollToEnd();

      await tester.pump();
      //wait for the animation to complete
      await tester.pumpAndSettle();

      expect(scrollController?.position.pixels, equals(0.0));
      // button should be hidden
      expect((finalState as dynamic).showScrollToBottom, isFalse);
    });

    testWidgets('preserves correct message order when displayed in reverse', (
      tester,
    ) async {
      final messagesState = ChatRoomState(
        messageList: List.generate(5, (index) => 'msg$index'),
        loading: const ChatRoomLoadingState.loaded(),
      );

      final mockNotifier = MockChatRoomMessagesNotifier(messagesState);

      await tester.pumpProviderWidget(
        overrides: [
          chatMessagesStateProvider(
            testRoomId,
          ).overrideWith((ref) => mockNotifier),
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

      // Get the AnimatedList
      final animatedList = tester.widget<AnimatedList>(
        find.byType(AnimatedList),
      );

      // Verify the list is in reverse
      expect(animatedList.reverse, isTrue);

      // Verify the correct number of items
      expect(animatedList.initialItemCount, equals(5));

      // Check the order of messages in the state
      expect(
        mockNotifier.state.messageList,
        equals(['msg0', 'msg1', 'msg2', 'msg3', 'msg4']),
      );
    });
  });
}
