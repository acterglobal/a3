import 'package:acter/features/chat_ng/widgets/events/virtual_day_divider_event_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_util.dart';

void main() {
  group('VirtualDayDividerEventWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      String? date,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [],
        child: VirtualDayDividerEventWidget(date: date),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('No date', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester);

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Today'), findsNothing);
      expect(find.text('Yesterday'), findsNothing);
    });

    testWidgets('Today date', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        date: DateTime.now().toIso8601String().split('T')[0],
      );

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Yesterday date', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        date:
            DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String()
                .split('T')[0],
      );

      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('Other date of same year', (WidgetTester tester) async {
      final currentYear = DateTime.now().year;
      await createWidgetUnderTest(tester: tester, date: '$currentYear-04-07');

      expect(find.text('Mon, 7 Apr'), findsOneWidget);
    });

    testWidgets('Other date of past year', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, date: '2024-04-07');

      expect(find.text('7 Apr, 2024'), findsOneWidget);
    });
  });
}
