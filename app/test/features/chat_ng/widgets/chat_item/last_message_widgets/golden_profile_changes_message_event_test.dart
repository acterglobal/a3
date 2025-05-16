import 'package:acter/features/chat_ng/rooms_list/widgets/chat_item_widget.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/profile_change_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/font_loader.dart';
import '../../../../../helpers/test_util.dart';

void main() {
  group('Chat NG - Last message widgets', () {
    testWidgets('Profile changes message event widget', (tester) async {
      await loadTestFonts();

      await tester.pumpProviderWidget(
        overrides: [],
        child: ListView(
          shrinkWrap: true,
          children: [
            Material(
              child: ChatItemWidget(
                roomId:
                    profileEventDisplayNameChangedRoom36(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    profileEventDisplayNameSetRoom37(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    profileEventDisplayNameUnsetRoom38(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    profileEventAvatarChangedRoom39(
                      '@emily:acter.global',
                    ).roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    profileEventAvatarSetRoom40('@emily:acter.global').roomId,
              ),
            ),
            Material(
              child: ChatItemWidget(
                roomId:
                    profileEventAvatarUnsetRoom41('@emily:acter.global').roomId,
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
        matchesGoldenFile('goldens/profile_changes_message_event.png'),
      );
    });
  });
}
