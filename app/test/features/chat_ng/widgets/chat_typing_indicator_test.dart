import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/features/chat_ng/providers/chat_typing_event_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_messages.dart';
import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TypingEvent, FfiListUserId;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:mocktail/mocktail.dart';

import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../common/mock_data/mock_user_id.dart';
import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_client_provider.dart';
import '../../../helpers/test_util.dart';

class MockTypingEvent extends Mock implements TypingEvent {}

class MockFfiListUserId extends Mock implements FfiListUserId {}

void main() {
  group('Typing Indicator in Chat UI - Widget Tests', () {
    testWidgets('displays typing indicator when users are typing', (
      tester,
    ) async {
      const roomId = 'test-room-id';

      final overrides = [
        chatTypingEventProvider.overrideWith(
          (ref, arg) => Stream.value(['user1', 'user2']),
        ),
        memberAvatarInfoProvider.overrideWith(
          (ref, info) => MockAvatarInfo(
            uniqueId: info.userId,
            mockDisplayName: info.userId == 'user1' ? 'Alice' : 'Bob',
          ),
        ),
      ];

      await tester.pumpProviderWidget(
        overrides: overrides,
        child: MaterialApp(
          theme: ActerTheme.theme,
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: ChatMessages(roomId: roomId)),
        ),
      );

      // add delay to allow the stream to emit and UI to update
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(TypingIndicator.typingRendererKey), findsOneWidget);

      expect(find.text('Alice and Bob are typing'), findsOneWidget);
    });

    testWidgets('displays nothing when no users are typing', (tester) async {
      const roomId = 'test-room-id';

      final overrides = [
        chatTypingEventProvider.overrideWith((ref, arg) => Stream.value([])),
      ];

      await tester.pumpProviderWidget(
        overrides: overrides,
        child: MaterialApp(
          theme: ActerTheme.theme,
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: ChatMessages(roomId: roomId)),
        ),
      );
      // add delay to allow the stream to emit and UI to update
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(TypingIndicator.typingRendererKey), findsNothing);
    });

    testWidgets('displays single user typing correctly', (tester) async {
      const roomId = 'test-room-id';

      final overrides = [
        chatTypingEventProvider.overrideWith(
          (ref, arg) => Stream.value(['user1']),
        ),
        memberAvatarInfoProvider.overrideWith(
          (ref, info) =>
              MockAvatarInfo(uniqueId: info.userId, mockDisplayName: 'Alice'),
        ),
      ];

      await tester.pumpProviderWidget(
        overrides: overrides,
        child: MaterialApp(
          theme: ActerTheme.theme,
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: ChatMessages(roomId: roomId)),
        ),
      );
      // add delay to allow the stream to emit and UI to update
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(TypingIndicator.typingRendererKey), findsOneWidget);
      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.text('Alice is typing'), findsOneWidget);
      expect(find.byType(AnimatedCircles), findsOneWidget);
    });

    testWidgets('handles multiple users typing correctly', (tester) async {
      const roomId = 'test-room-id';

      final overrides = [
        chatTypingEventProvider.overrideWith(
          (ref, arg) => Stream.value(['user1', 'user2', 'user3', 'user4']),
        ),
        memberAvatarInfoProvider.overrideWith((ref, info) {
          return switch (info.userId) {
            'user1' => MockAvatarInfo(
              uniqueId: 'user1',
              mockDisplayName: 'Alice',
            ),
            'user2' => MockAvatarInfo(
              uniqueId: 'user2',
              mockDisplayName: 'Bob',
            ),
            'user3' => MockAvatarInfo(
              uniqueId: 'user3',
              mockDisplayName: 'Charlie',
            ),
            'user4' => MockAvatarInfo(
              uniqueId: 'user4',
              mockDisplayName: 'Dave',
            ),
            _ => MockAvatarInfo(
              uniqueId: info.userId,
              mockDisplayName: info.userId,
            ),
          };
        }),
      ];

      await tester.pumpProviderWidget(
        overrides: overrides,
        child: MaterialApp(
          theme: ActerTheme.theme,
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: ChatMessages(roomId: roomId)),
        ),
      );
      // add delay to allow the stream to emit and UI to update
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(TypingIndicator.typingRendererKey), findsOneWidget);
      expect(find.byType(ActerAvatar), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Alice and 3 others are typing'), findsOneWidget);
      expect(find.byType(AnimatedCircles), findsOneWidget);
    });
  });

  group('Chat Typing Event Provider tests', () {
    late MockClient mockClient;
    late MockTypingEvent mockTypingEvent;
    late MockFfiListUserId mockUserIdList;

    setUp(() {
      registerFallbackValue(MockUserId('fallback'));
      mockClient = MockClient();
      mockTypingEvent = MockTypingEvent();
      mockUserIdList = MockFfiListUserId();

      when(() => mockTypingEvent.userIds()).thenReturn(mockUserIdList);
      when(
        () => mockClient.subscribeToTypingEventStream(any()),
      ).thenAnswer((_) => Stream.value(mockTypingEvent));
    });

    test('filters out current user from typing users list', () async {
      const roomId = 'test-room-id';
      const currentUserId = 'current-user';

      final user1 = MockUserId('user1');
      final user2 = MockUserId('user2');
      final currentUser = MockUserId(currentUserId);

      final usersList = [user1, currentUser, user2];
      when(() => mockUserIdList.toList()).thenReturn(usersList);

      final mockClientNotifier = MockClientNotifier(client: mockClient);
      final container = ProviderContainer(
        overrides: [
          clientProvider.overrideWith(() => mockClientNotifier),
          myUserIdStrProvider.overrideWithValue(currentUserId),
        ],
      );

      // listen to the provider
      final result = await container.read(
        chatTypingEventProvider(roomId).future,
      );

      // verify the current user is filtered out
      expect(result, ['user1', 'user2']);
      expect(result, isNot(contains(currentUserId)));
      expect(result.length, equals(2));

      // verify the methods were called
      verify(() => mockClient.subscribeToTypingEventStream(roomId)).called(1);
      verify(() => mockTypingEvent.userIds()).called(1);
      verify(() => mockUserIdList.toList()).called(1);
    });

    test('handles empty typing users list', () async {
      const roomId = 'test-room-id';
      const currentUserId = 'current-user';

      when(() => mockUserIdList.toList()).thenReturn([]);

      final mockClientNotifier = MockClientNotifier(client: mockClient);
      final container = ProviderContainer(
        overrides: [
          clientProvider.overrideWith(() => mockClientNotifier),
          myUserIdStrProvider.overrideWithValue(currentUserId),
        ],
      );

      // listen to the provider
      final result = await container.read(
        chatTypingEventProvider(roomId).future,
      );

      // verify we get an empty list
      expect(result, isEmpty);
      expect(result.length, equals(0));

      // verify the methods were called
      verify(() => mockClient.subscribeToTypingEventStream(roomId)).called(1);
      verify(() => mockTypingEvent.userIds()).called(1);
      verify(() => mockUserIdList.toList()).called(1);
    });
  });
}
