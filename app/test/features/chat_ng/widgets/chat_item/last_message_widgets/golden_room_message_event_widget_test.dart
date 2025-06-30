import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/rooms_list/widgets/chat_item_widget.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/membership_usecases.dart';
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
            () => MockSelectedChatIdNotifier(
              membershipEventjoinedRoom22('@emily:acter.global').roomId,
            ),
          ),
          utcNowProvider.overrideWith(
            (ref) => MockUtcNowNotifier(ts: 1744707051000),
          ), // April
        ],
        child: ListView(
          shrinkWrap: true,
          children: [
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventjoinedRoom22('@emily:acter.global').roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId: membershipEventLeftRoom23('@emily:acter.global').roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventInvitationAcceptedRoom24(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventInvitationRejectedRoom25(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventInvitationRevokedRoom26(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventKnockAcceptedRoom27(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventKnockRetractedRoom28(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventKnockDeniedRoom29(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventBannedRoom30('@emily:acter.global').roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventUnbannedRoom31('@emily:acter.global').roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventKickedRoom32('@emily:acter.global').roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventInvitedRoom33('@emily:acter.global').roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventKickedAndBannedRoom34(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    membershipEventKnockedRoom35('@emily:acter.global').roomId,
              ),
            ),
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
