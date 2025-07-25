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

  group('Chat NG - ChatEvent reply message emoji only golden', () {
    testWidgets(
      'ChatEvent reply-to message emoji only event widget legacy html',
      (tester) async {
        await loadTestFonts();
        goldenFileComparator = test_utils.GoldenFileComparator(goldenDir);

        await tester.pumpProviderWidget(
          overrides: [
            myUserIdStrProvider.overrideWith(
              (ref) => '@acter1:m-1.acter.global',
            ),
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
                  roomId:
                      productTeamMutedWithSingleTypingUserRoom2(
                        '@emily:acter.global',
                      ).roomId,
                  eventId: 'mock-reply-emoji-only',
                ),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ListView),
          matchesGoldenFile(
            'goldens_images/chat_event_reply_with_emoji_only_legacy_html.png',
          ),
        );
      },
    );
    testWidgets(
      'ChatEvent reply-to message emoji only event widget html next',
      (tester) async {
        await loadTestFonts();
        goldenFileComparator = test_utils.GoldenFileComparator(goldenDir);
        useGoldenFileComparatorWithThreshold(0.05);

        await tester.pumpProviderWidget(
          overrides: [
            myUserIdStrProvider.overrideWith(
              (ref) => '@acter1:m-1.acter.global',
            ),
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
                  roomId:
                      productTeamMutedWithSingleTypingUserRoom2(
                        '@emily:acter.global',
                      ).roomId,
                  eventId: 'mock-reply-emoji-only',
                ),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ListView),
          matchesGoldenFile(
            'goldens_images/chat_event_reply_with_emoji_only_html_next.png',
          ),
        );
      },
    );
  });
}
