import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/rooms_list/widgets/chat_item_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_data.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/font_loader.dart';
import '../../../../../helpers/mock_event_providers.dart';
import '../../../../../helpers/test_util.dart';
import '../selected_chat_item_test.dart';

void main() {
  group('Chat NG - Last message widgets', () {
    testWidgets('Room membership event widget', (tester) async {
      await loadTestFonts();

      await tester.pumpProviderWidget(
        overrides: [
          isActiveProvider(LabsFeature.chatNG).overrideWith((ref) => true),
          selectedChatIdProvider.overrideWith(
            () =>
                MockSelectedChatIdNotifier(membershipEventjoinedRoom22.roomId),
          ),
          utcNowProvider.overrideWith(
            (ref) => MockUtcNowNotifier(ts: 1744707051000),
          ), // April
        ],
        child: ListView(
          shrinkWrap: true,
          children: [
            ChatItemWidget(roomId: membershipEventjoinedRoom22.roomId),
            ChatItemWidget(roomId: membershipEventLeftRoom23.roomId),
            ChatItemWidget(
              roomId: membershipEventInvitationAcceptedRoom24.roomId,
            ),
            ChatItemWidget(
              roomId: membershipEventInvitationRejectedRoom25.roomId,
            ),
            ChatItemWidget(
              roomId: membershipEventInvitationRevokedRoom26.roomId,
            ),
            ChatItemWidget(roomId: membershipEventKnockAcceptedRoom27.roomId),
            ChatItemWidget(roomId: membershipEventKnockRetractedRoom28.roomId),
            ChatItemWidget(roomId: membershipEventKnockDeniedRoom29.roomId),
            ChatItemWidget(roomId: membershipEventBannedRoom30.roomId),
            ChatItemWidget(roomId: membershipEventUnbannedRoom31.roomId),
            ChatItemWidget(roomId: membershipEventKickedRoom32.roomId),
            ChatItemWidget(roomId: membershipEventInvitedRoom33.roomId),
            ChatItemWidget(roomId: membershipEventKickedAndBannedRoom34.roomId),
            ChatItemWidget(roomId: membershipEventKnockedRoom35.roomId),
          ],
        ),
      );

      await tester.pump(Duration(seconds: 1));
      await tester.pump(Duration(seconds: 1));
      await tester.pump(Duration(seconds: 1));

      await expectLater(
        find.byType(ListView),
        matchesGoldenFile('goldens/room_message_event_widget.png'),
      );
    });
  });
}
