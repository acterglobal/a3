import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/chat_list_widget.dart';
import 'package:acter/features/chat_ng/rooms_list/widgets/chat_item_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_data.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../helpers/mock_event_providers.dart';
import '../../../../helpers/test_util.dart';
import '../../../../helpers/font_loader.dart';

void main() {
  group('Chat NG Room items', () {
    testWidgets('unread counter visible on selection ', (tester) async {
      await loadTestFonts();
      final chatListprovider = Provider<List<Convo>>(
        (ref) => [emilyDmMutedBookmarked.mockConvo],
      );

      await tester.pumpProviderWidget(
        overrides: [
          isActiveProvider(LabsFeature.chatNG).overrideWith((ref) => true),
          isActiveProvider(LabsFeature.chatUnread).overrideWith((ref) => true),
          utcNowProvider.overrideWith(
            (ref) => MockUtcNowNotifier(ts: 1744707051000),
          ), // April 15th, 2025
        ],
        child: ChatListWidget(
          chatListProvider: chatListprovider,
          showSelectedIndication: true,
          emptyState: Text('empty state'),
        ),
      );

      await tester.pump(Duration(seconds: 1));

      expect(find.byType(ChatItemWidget), findsOneWidget);

      final element = tester.element(find.byType(ChatItemWidget));
      final container = ProviderScope.containerOf(element);
      container
          .read(selectedChatIdProvider.notifier)
          .select(emilyDmMutedBookmarked.roomId); // set to our room

      await tester.pump(Duration(seconds: 1));
      await tester.pump(Duration(seconds: 1));

      await expectLater(
        find.byType(ChatItemWidget),
        matchesGoldenFile('goldens/unread_counter_visible_on_selection.png'),
      );
    });
  });
}
