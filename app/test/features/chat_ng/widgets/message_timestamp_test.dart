import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('Message Timestamp Widget Tests', () {
    testWidgets('displays timestamp in proper format based on system settings', (
      tester,
    ) async {
      final specificDateTime = DateTime(2023, 1, 1, 12, 0, 0);
      final timestamp = specificDateTime.millisecondsSinceEpoch;

      await tester.pumpProviderWidget(
        child: MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: MessageTimestampWidget(timestamp: timestamp)),
            ),
          ),
        ),
      );

      final textWidget24h = tester.widget<Text>(find.byType(Text));
      final displayedText24h = textWidget24h.data ?? '';

      expect(
        displayedText24h.contains('AM') || displayedText24h.contains('PM'),
        isFalse,
        reason: 'With 24-hour format enabled, time should not contain AM/PM',
      );

      expect(
        displayedText24h.contains(':'),
        isTrue,
        reason:
            'Time display should contain a colon separating hours and minutes',
      );

      await tester.pumpProviderWidget(
        child: MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: false),
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: MessageTimestampWidget(timestamp: timestamp)),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textWidget12h = tester.widget<Text>(find.byType(Text));
      final displayedText12h = textWidget12h.data ?? '';

      expect(
        displayedText12h.isNotEmpty && RegExp(r'\d').hasMatch(displayedText12h),
        isTrue,
        reason: 'Time should be displayed with digits',
      );
    });
  });
}
