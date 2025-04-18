import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/features/chat_ng/rooms_list/widgets/chat_item_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_data.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_event_providers.dart';
import '../../../../helpers/test_util.dart';
import '../../../../helpers/font_loader.dart';

class MockSelectedChatIdNotifier extends SelectedChatIdNotifier {
  MockSelectedChatIdNotifier(this.initialValue);

  final String? initialValue;

  @override
  String? build() => initialValue;

  @override
  void select(String? roomId) {
    super.select(roomId);
  }
}

void main() {
  group('Chat NG Room items', () {
    testWidgets('unread counter visible on selection ', (tester) async {
      await loadTestFonts();

      await tester.pumpProviderWidget(
        overrides: [
          isActiveProvider(LabsFeature.chatNG).overrideWith((ref) => true),
          isActiveProvider(LabsFeature.chatUnread).overrideWith((ref) => true),
          selectedChatIdProvider.overrideWith(
            () =>
                MockSelectedChatIdNotifier(emilyDmMutedBookmarkedRoom1.roomId),
          ),
          utcNowProvider.overrideWith(
            (ref) => MockUtcNowNotifier(ts: 1744707051000),
          ), // April 15th, 2025
        ],
        child: ListView(
          shrinkWrap: true,
          children: [
            ChatItemWidget(
              roomId: emilyDmMutedBookmarkedRoom1.roomId,
              showSelectedIndication: true,
            ),
          ],
        ),
      );

      expect(find.byType(ChatItemWidget), findsOneWidget);
      await tester.pump(Duration(seconds: 1));
      await tester.pump(Duration(seconds: 1));
      await tester.pump(Duration(seconds: 1));

      await expectLater(
        find.byType(ChatItemWidget),
        matchesGoldenFile('goldens/unread_counter_visible_on_selection.png'),
      );
    });
  });
}
