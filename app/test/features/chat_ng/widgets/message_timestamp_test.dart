import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('Message Timestamp Widget Tests', () {
    testWidgets(
      'displays timestamp in proper format based on system settings',
      (tester) async {
        final specificDateTime = DateTime(2023, 1, 1, 12, 0, 0);
        final timestamp = specificDateTime.millisecondsSinceEpoch;
        final jiffyTime = Jiffy.parseFromMillisecondsSinceEpoch(timestamp);

        await tester.pumpProviderWidget(
          child: MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: true),
            child: MessageTimestampWidget(timestamp: timestamp),
          ),
        );

        final textWidget24h = tester.widget<Text>(find.byType(Text));
        final displayedText24h = textWidget24h.data ?? '';

        final expected24h = jiffyTime.Hm;
        expect(displayedText24h, equals(expected24h));

        await tester.pumpWidget(Container());

        await tester.pumpProviderWidget(
          child: MessageTimestampWidget(timestamp: timestamp),
        );

        await tester.pumpAndSettle();

        final textWidget12h = tester.widget<Text>(find.byType(Text));
        final displayedText12h = textWidget12h.data ?? '';

        final expected12h = jiffyTime.jm;
        expect(displayedText12h, equals(expected12h));
      },
    );
  });
}
