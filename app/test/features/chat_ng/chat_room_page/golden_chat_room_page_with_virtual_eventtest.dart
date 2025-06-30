import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/features/chat_ng/pages/chat_room.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/general_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../helpers/font_loader.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the platform channels to prevent MissingPluginException
  const channel = MethodChannel('keyboardHeightEventChannel');
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async => null,
  );

  group('Chat NG - ChatRoomPage with Virtual Events golden', () {
    testWidgets('ChatRoomPage with Virtual Events widget', (tester) async {
      await loadTestFonts();

      final overrides = [
        myUserIdStrProvider.overrideWith((ref) => '@acter1:m-1.acter.global'),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(overrides: overrides),
          child: MaterialApp(
            theme: ActerTheme.theme,
            darkTheme: ActerTheme.theme,
            themeMode: ThemeMode.dark,
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: ChatRoomNgPage(
              roomId:
                  engineeringTeamWithTestUpdateRoom3(
                    '@acter1:m-1.acter.global',
                  ).roomId,
            ),
          ),
        ),
      );

      // Initial pump to start animations
      await tester.pump();

      // Wait for initial animations
      await tester.pump(const Duration(milliseconds: 500));

      // Wait for any remaining animations
      await tester.pump(const Duration(milliseconds: 500));

      // Final pump to ensure everything is settled
      await tester.pump();

      await expectLater(
        find.byType(ChatRoomNgPage),
        matchesGoldenFile(
          'goldens_images/chat_room_page_with_virtual_events.png',
        ),
      );
    });
  });
}
