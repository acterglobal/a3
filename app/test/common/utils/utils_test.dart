import 'package:acter/common/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

void main() {
  group('Editor Content Validation', () {
    test('returns false for empty plain text', () {
      expect(
        hasValidEditorContent(plainText: '', html: '<p>Some content</p>'),
        false,
      );
    });

    test('returns false for empty HTML', () {
      expect(hasValidEditorContent(plainText: 'Some text', html: ''), false);
    });

    test('returns false for whitespace-only plain text', () {
      expect(
        hasValidEditorContent(plainText: '   ', html: '<p>Some content</p>'),
        false,
      );
    });

    test('returns false for HTML with only <br> tag', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<br>'),
        false,
      );
    });

    test('returns false for HTML with only empty paragraph', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p></p>'),
        false,
      );
    });

    test('returns false for HTML with only whitespace in paragraph', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p>   </p>'),
        false,
      );
    });

    test('returns false for HTML with only &nbsp;', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p>&nbsp;</p>'),
        false,
      );
    });

    test('returns true for valid plain text and HTML content', () {
      expect(
        hasValidEditorContent(
          plainText: 'Hello World',
          html: '<p>Hello World</p>',
        ),
        true,
      );
    });

    test('returns true for HTML with formatting but valid content', () {
      expect(
        hasValidEditorContent(
          plainText: 'Hello World',
          html: '<p><strong>Hello</strong> <em>World</em></p>',
        ),
        true,
      );
    });

    test('returns true for HTML with multiple paragraphs', () {
      expect(
        hasValidEditorContent(
          plainText: 'Hello\nWorld',
          html: '<p>Hello</p><p>World</p>',
        ),
        true,
      );
    });

    test('returns true for HTML with line breaks and content', () {
      expect(
        hasValidEditorContent(
          plainText: 'Hello\nWorld',
          html: '<p>Hello<br>World</p>',
        ),
        true,
      );
    });
  });

  group('jiffyDateTimestamp unit tests', () {
    late BuildContext context;
    late MediaQueryData mediaQueryData;

    testWidgets('jiffyDateTimestamp returns only time when showDay is false', (
      WidgetTester tester,
    ) async {
      mediaQueryData = const MediaQueryData(alwaysUse24HourFormat: false);

      final widget = MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Container();
          },
        ),
      );

      await tester.pumpWidget(widget);
      context = tester.element(find.byType(Container));

      final now = DateTime.now();
      final timeInterval = now.millisecondsSinceEpoch;

      final result = jiffyDateTimestamp(context, timeInterval, showDay: false);

      expect(result, Jiffy.parseFromDateTime(now).jm);
    });

    testWidgets(
      'jiffyDateTimestamp returns time in 24-hour format when alwaysUse24HourFormat is true',
      (WidgetTester tester) async {
        mediaQueryData = const MediaQueryData(alwaysUse24HourFormat: true);

        final widget = MaterialApp(
          home: MediaQuery(
            data: mediaQueryData,
            child: Builder(
              builder: (BuildContext context) {
                return Container();
              },
            ),
          ),
        );

        await tester.pumpWidget(widget);
        context = tester.element(find.byType(Container));

        final now = DateTime.now();
        final timeInterval = now.millisecondsSinceEpoch;

        final result = jiffyDateTimestamp(
          context,
          timeInterval,
          showDay: false,
        );

        expect(result, Jiffy.parseFromDateTime(now).Hm);
      },
    );

    testWidgets('jiffyDateTimestamp returns time only for same day', (
      WidgetTester tester,
    ) async {
      mediaQueryData = const MediaQueryData(alwaysUse24HourFormat: false);

      final widget = MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Container();
          },
        ),
      );

      await tester.pumpWidget(widget);
      context = tester.element(find.byType(Container));

      final now = DateTime.now();
      final timeInterval = now.millisecondsSinceEpoch;

      final result = jiffyDateTimestamp(context, timeInterval, showDay: true);

      expect(result, Jiffy.parseFromDateTime(now).jm);
    });

    testWidgets(
      'jiffyDateTimestamp returns day and time for dates within current week',
      (WidgetTester tester) async {
        mediaQueryData = const MediaQueryData(alwaysUse24HourFormat: false);

        final widget = MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Container();
            },
          ),
        );

        await tester.pumpWidget(widget);
        context = tester.element(find.byType(Container));

        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        final timeInterval = threeDaysAgo.millisecondsSinceEpoch;

        final result = jiffyDateTimestamp(context, timeInterval, showDay: true);

        final expected =
            '${Jiffy.parseFromDateTime(threeDaysAgo).E} ${Jiffy.parseFromDateTime(threeDaysAgo).jm}';
        expect(result, expected);
      },
    );

    testWidgets(
      'jiffyDateTimestamp returns month day and time for dates within current year',
      (WidgetTester tester) async {
        mediaQueryData = const MediaQueryData(alwaysUse24HourFormat: false);

        final widget = MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Container();
            },
          ),
        );

        await tester.pumpWidget(widget);
        context = tester.element(find.byType(Container));

        final now = DateTime.now();
        final threeMonthsAgo = now.subtract(const Duration(days: 90));
        final timeInterval = threeMonthsAgo.millisecondsSinceEpoch;

        final result = jiffyDateTimestamp(context, timeInterval, showDay: true);

        final expected =
            '${Jiffy.parseFromDateTime(threeMonthsAgo).MMMEd} ${Jiffy.parseFromDateTime(threeMonthsAgo).jm}';
        expect(result, expected);
      },
    );

    testWidgets(
      'jiffyDateTimestamp returns full date and time for dates older than a year',
      (WidgetTester tester) async {
        mediaQueryData = const MediaQueryData(alwaysUse24HourFormat: false);

        final widget = MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Container();
            },
          ),
        );

        await tester.pumpWidget(widget);
        context = tester.element(find.byType(Container));

        final now = DateTime.now();
        final twoYearsAgo = now.subtract(const Duration(days: 730));
        final timeInterval = twoYearsAgo.millisecondsSinceEpoch;

        final result = jiffyDateTimestamp(context, timeInterval, showDay: true);

        final expected =
            '${Jiffy.parseFromDateTime(twoYearsAgo).yMMMEd} ${Jiffy.parseFromDateTime(twoYearsAgo).jm}';
        expect(result, expected);
      },
    );
  });
}
