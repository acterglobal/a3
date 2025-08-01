import 'dart:io';

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
import '../../../../../helpers/utils.dart' as test_utils;

void main() {
  final testDir = Directory.current.path;
  final goldenDir =
      '$testDir/test/features/chat_ng/widgets/chat_room/chat_event_messages/goldens_images';

  goldenFileComparator = test_utils.GoldenFileComparator(goldenDir);

  group('Chat NG : DM Chat - ChatEvent reactions message golden', () {
    testWidgets('ChatEvent reactions message event widget - legacy html', (
      tester,
    ) async {
      await loadTestFonts();

      goldenFileComparator = test_utils.GoldenFileComparator(goldenDir);

      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((ref) => '@acter1:m-1.acter.global'),
          isActiveProvider(LabsFeature.htmlNext).overrideWith((ref) => false),
          messageReadReceiptsProvider.overrideWith(
            (ref, item) => {'@acter1:m-1.acter.global': 1716230400},
          ),
        ],
        child: ListView(
          shrinkWrap: true,
          children: [
            Material(
              child: ChatEvent(
                roomId: emilyDmMutedBookmarkedRoom1RoomId,
                eventId: 'mock-event-id-19',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId: emilyDmMutedBookmarkedRoom1RoomId,
                eventId: 'mock-event-id-22',
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ListView),
        matchesGoldenFile(
          'goldens_images/chat_event_reactions_message_event_dm_chat.png',
        ),
      );
    });
    testWidgets('ChatEvent reactions message event widget - html next', (
      tester,
    ) async {
      await loadTestFonts();
      goldenFileComparator = test_utils.GoldenFileComparator(goldenDir);
      useGoldenFileComparatorWithThreshold(0.30);

      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((ref) => '@acter1:m-1.acter.global'),
          isActiveProvider(LabsFeature.htmlNext).overrideWith((ref) => true),
          messageReadReceiptsProvider.overrideWith(
            (ref, item) => {'@acter1:m-1.acter.global': 1716230400},
          ),
        ],
        child: ListView(
          shrinkWrap: true,
          children: [
            Material(
              child: ChatEvent(
                roomId: emilyDmMutedBookmarkedRoom1RoomId,
                eventId: 'mock-event-id-19',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId: emilyDmMutedBookmarkedRoom1RoomId,
                eventId: 'mock-event-id-22',
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ListView),
        matchesGoldenFile(
          'goldens_images/chat_event_reactions_message_event_dm_chat_html_next.png',
        ),
      );
    });
  });
}
