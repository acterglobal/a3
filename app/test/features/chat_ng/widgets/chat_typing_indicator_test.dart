import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/chat_messages.dart';
import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acter/l10n/generated/l10n.dart';

import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/test_util.dart';

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

      expect(find.byType(TypingIndicator), findsOneWidget);

      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.textContaining('Bob'), findsOneWidget);
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

      expect(find.byType(TypingIndicator), findsNothing);
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

      expect(find.byType(TypingIndicator), findsOneWidget);

      expect(find.textContaining('Alice'), findsOneWidget);
    });

    testWidgets('handles multiple users typing correctly', (tester) async {
      const roomId = 'test-room-id';

      final overrides = [
        chatTypingEventProvider.overrideWith(
          (ref, arg) => Stream.value(['user1', 'user2', 'user3', 'user4']),
        ),
        memberAvatarInfoProvider.overrideWith((ref, info) {
          switch (info.userId) {
            case 'user1':
              return MockAvatarInfo(
                uniqueId: 'user1',
                mockDisplayName: 'Alice',
              );
            case 'user2':
              return MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'Bob');
            case 'user3':
              return MockAvatarInfo(
                uniqueId: 'user3',
                mockDisplayName: 'Charlie',
              );
            case 'user4':
              return MockAvatarInfo(uniqueId: 'user4', mockDisplayName: 'Dave');
            default:
              return MockAvatarInfo(
                uniqueId: info.userId,
                mockDisplayName: info.userId,
              );
          }
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

      expect(find.byType(TypingIndicator), findsOneWidget);

      expect(find.textContaining('Alice'), findsOneWidget);

      expect(find.textContaining('3'), findsOneWidget);
    });
  });
}
