import 'package:acter/features/chat_ng/rooms_list/widgets/chat_item_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/font_loader.dart';
import '../../../../../helpers/test_util.dart';

void main() {
  group('Chat NG - Last message widgets', () {
    testWidgets('Text and media message event widget', (tester) async {
      await loadTestFonts();

      await tester.pumpProviderWidget(
        overrides: [],
        child: ListView(
          shrinkWrap: true,
          children: [
            Card(child: ChatItemWidget(roomId: davidDmRoom15.roomId)),
            Card(child: ChatItemWidget(roomId: imageMessageDmRoom16.roomId)),
            Card(child: ChatItemWidget(roomId: videoMessageDmRoom17.roomId)),
            Card(child: ChatItemWidget(roomId: audioMessageDmRoom18.roomId)),
            Card(child: ChatItemWidget(roomId: fileMessageDmRoom19.roomId)),
            Card(child: ChatItemWidget(roomId: locationMessageDmRoom20.roomId)),
          ],
        ),
      );

      await tester.pump(Duration(seconds: 1));
      await tester.pump(Duration(seconds: 1));
      await tester.pump(Duration(seconds: 1));

      await expectLater(
        find.byType(ListView),
        matchesGoldenFile('goldens/text_and_media_message_event.png'),
      );
    });
  });
}
