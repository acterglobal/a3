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
  group('Chat NG - ChatEvent link message golden', () {
    testWidgets('ChatEvent link html message event widget legacy html', (
      tester,
    ) async {
      await loadTestFonts();
      useGoldenFileComparatorWithThreshold(0.01); // 1%

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
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-url-html-1',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-url-html-2',
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
        matchesGoldenFile('goldens_images/chat_event_link_message_event.png'),
      );
    });
    testWidgets('ChatEvent link html message event widget html next', (
      tester,
    ) async {
      await loadTestFonts();
      useGoldenFileComparatorWithThreshold(0.005); // 0.5% change for CI

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
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-url-html-1',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-url-html-2',
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
          'goldens_images/chat_event_link_message_event_html_next.png',
        ),
      );
    });
    testWidgets('ChatEvent auto link message event widget legacy html', (
      tester,
    ) async {
      await loadTestFonts();
      useGoldenFileComparatorWithThreshold(0.01); // 1%

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
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-url-1',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-url-2',
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
          'goldens_images/chat_event_autolink_message_event.png',
        ),
      );
    });
    testWidgets('ChatEvent autolink message event widget html next', (
      tester,
    ) async {
      await loadTestFonts();
      useGoldenFileComparatorWithThreshold(0.005); // 0.5% change for CI

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
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-url-1',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-url-2',
              ),
            ),

            Material(
              child: ChatEvent(
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-acter-url-1',
              ),
            ),

            Material(
              child: ChatEvent(
                roomId:
                    productTeamMutedWithSingleTypingUserRoom2(
                      '@emily:acter.global',
                    ).roomId,
                eventId: 'mock-user-url-1',
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
          'goldens_images/chat_event_autolink_message_event_html_next.png',
        ),
      );
    });
  });
}
