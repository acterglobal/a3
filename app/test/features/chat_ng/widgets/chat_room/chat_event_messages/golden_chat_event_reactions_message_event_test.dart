import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/general_usecases.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';
import '../../../../../helpers/font_loader.dart';
import '../../../../../helpers/test_util.dart';

void main() {
  group('Chat NG - ChatEvent reactions message golden', () {
    testWidgets('ChatEvent reactions message event widget legacy html', (
      tester,
    ) async {
      await loadTestFonts();
      useGoldenFileComparatorWithThreshold(0.01); // 1%

      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((ref) => '@acter1:m-1.acter.global'),
          messageReadReceiptsProvider.overrideWith(
            (ref, item) => {'@acter1:m-1.acter.global': 1716230400},
          ),
          isActiveProvider(LabsFeature.htmlNext).overrideWith((ref) => false),
        ],
        child: ListView(
          shrinkWrap: true,
          children: [
            Material(
              child: ChatEvent(
                roomId: productTeamMutedWithSingleTypingUserRoom2RoomId,
                eventId: 'mock-reply-1',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId: productTeamMutedWithSingleTypingUserRoom2RoomId,
                eventId: 'mock-reply-2',
              ),
            ),
          ],
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(ListView),
        matchesGoldenFile(
          'goldens_images/chat_event_reactions_message_event_legacy_html.png',
        ),
      );
    });
    testWidgets('ChatEvent reactions message event widget html next', (
      tester,
    ) async {
      await loadTestFonts();
      useGoldenFileComparatorWithThreshold(0.01); // 1%

      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((ref) => '@acter1:m-1.acter.global'),
          messageReadReceiptsProvider.overrideWith(
            (ref, item) => {'@acter1:m-1.acter.global': 1716230400},
          ),
          isActiveProvider(LabsFeature.htmlNext).overrideWith((ref) => true),
        ],
        child: ListView(
          shrinkWrap: true,
          children: [
            Material(
              child: ChatEvent(
                roomId: productTeamMutedWithSingleTypingUserRoom2RoomId,
                eventId: 'mock-reply-1',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId: productTeamMutedWithSingleTypingUserRoom2RoomId,
                eventId: 'mock-reply-2',
              ),
            ),
          ],
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(ListView),
        matchesGoldenFile(
          'goldens_images/chat_event_reactions_message_event_html_next.png',
        ),
      );
    });
  });
}
