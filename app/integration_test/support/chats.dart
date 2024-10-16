import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/chat/widgets/convo_card.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

extension ActerChat on ConvenientTest {
  Future<void> ensureHasChats({int? counter, List<String>? ids}) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final homeKey = find.byKey(MainNavKeys.chats);
    await homeKey.should(findsOneWidget);
    await homeKey.tap();

    final select = find.byKey(RoomsListWidget.roomListMenuKey);
    await tester.ensureVisible(select);

    if (counter != null) {
      final select = find.byType(ConvoCard);
      await select.should(findsNWidgets(counter));
    }

    if (ids != null && ids.isNotEmpty == true) {
      for (final id in ids) {
        final select = find.byKey(Key('convo-card-$id'));
        await tester.ensureVisible(select);
      }
    }
  }
}
