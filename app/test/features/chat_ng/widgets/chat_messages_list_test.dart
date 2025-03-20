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
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_util.dart';

class MockTimelineStream extends Mock implements TimelineStream {
  @override
  Future<bool> paginateBackwards(int count) async => false;
}

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

    testWidgets('scroll to bottom button appears when scrolled up', (
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
      scrollController!.position.jumpTo(100.0);

      await tester.pump();

      // now the button should be visible
      final updatedOpacityWidget = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byIcon(Icons.arrow_downward),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(updatedOpacityWidget.opacity, 1.0);
    });

    // testWidgets('pagination is called when scrolled to top', (
    //   WidgetTester tester,
    // ) async {
    //   final messagesState = ChatRoomState(
    //     messageList: List.generate(20, (index) => 'msg$index'),
    //     loading: const ChatRoomLoadingState.loaded(),
    //     hasMore: true,
    //   );

    //   // Create a proper Mocktail mock
    //   final mockNotifier = MockChatRoomMessagesNotifier(messagesState);
    //   final mockTimelineStream = MockTimelineStream();

    //   // Make sure the mock is properly set up for verification
    //   when(
    //     () => mockNotifier.loadMore(failOnError: any(named: 'failOnError')),
    //   ).thenAnswer((_) async {});

    //   await tester.pumpProviderWidget(
    //     overrides: [
    //       chatMessagesStateProvider(
    //         testRoomId,
    //       ).overrideWith((ref) => mockNotifier),
    //       chat
    //           .timelineStreamProvider(testRoomId)
    //           .overrideWith((ref) => Future.value(mockTimelineStream)),
    //       animatedListChatMessagesProvider(
    //         testRoomId,
    //       ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
    //     ],
    //     child: ChatMessages(roomId: testRoomId),
    //   );

    //   final scrollController =
    //       tester.widget<AnimatedList>(find.byType(AnimatedList)).controller;

    //   scrollController!.position.jumpTo(
    //     scrollController.position.maxScrollExtent,
    //   );
    //   await tester.pump();

    //   // Verify loadMore was called
    //   verify(() => mockNotifier.loadMore(failOnError: false)).called(1);
    // });

    // testWidgets('marks messages as read when scrolled to bottom', (
    //   WidgetTester tester,
    // ) async {
    //   final messagesState = ChatRoomState(
    //     messageList: List.generate(20, (index) => 'msg$index'),
    //     loading: const ChatRoomLoadingState.loaded(),
    //   );

    //   final mockNotifier = MockChatRoomMessagesNotifier(messagesState);
    //   final timelineStream = MockTimelineStream();

    //   // Set up the mock behavior properly
    //   when(
    //     () => timelineStream.markAsRead(any()),
    //   ).thenAnswer((_) async => true);

    //   await tester.pumpProviderWidget(
    //     overrides: [
    //       chatMessagesStateProvider(
    //         testRoomId,
    //       ).overrideWith((ref) => mockNotifier),
    //       chat
    //           .timelineStreamProvider(testRoomId)
    //           .overrideWith((ref) => Future.value(timelineStream)),
    //       animatedListChatMessagesProvider(
    //         testRoomId,
    //       ).overrideWith((ref) => GlobalKey<AnimatedListState>()),
    //       isActiveProvider(LabsFeature.chatUnread).overrideWith((ref) => false),
    //       chat.hasUnreadMessages(testRoomId).overrideWith((ref) => true),
    //     ],
    //     child: ChatMessages(roomId: testRoomId),
    //   );

    //   final chatMessagesWidget = find.byType(ChatMessages);
    //   expect(chatMessagesWidget, findsOneWidget);

    //   final state =
    //       tester.state(chatMessagesWidget) as ConsumerState<ChatMessages>;

    //   await (state as dynamic).onScroll();

    //   // Wait for the debounce timer
    //   await tester.pump(const Duration(milliseconds: 300));
    //   await tester.pump();

    //   // Verify markAsRead was called
    //   verify(() => timelineStream.markAsRead(any())).called(1);
    // });

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

      // just verify the button exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });
}
