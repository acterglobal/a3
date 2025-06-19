import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/general_usecases.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';
import '../../../../../helpers/font_loader.dart';
import '../../../../../helpers/test_util.dart';

void main() {
  group('Chat NG - ChatEvent audio message golden', () {
    testWidgets('ChatEvent audio message event widget', (
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
          // Mock audio player to avoid plugin initialization
          audioPlayerStateProvider.overrideWith(
            (ref) => (state: PlayerState.stopped, messageId: null),
          ),
        ],
        child: ListView(
          shrinkWrap: true,
          children: [
            Material(
              child: ChatEvent(
                roomId: productTeamMutedWithSingleTypingUserRoom2RoomId,
                eventId: 'mock-audio-1',
              ),
            ),
            Material(
              child: ChatEvent(
                roomId: productTeamMutedWithSingleTypingUserRoom2RoomId,
                eventId: 'mock-audio-2',
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
          'goldens_images/chat_event_audio_message_event.png',
        ),
      );
    }, skip: true); // Skip due to AudioPlayer plugin initialization issues in tests
  });
}
