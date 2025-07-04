import 'package:acter/common/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

void main() {
  group('Empty HTML Content Detection', () {
    test('isEmptyHtmlContent returns true for empty string', () {
      expect(isEmptyHtmlContent(''), true);
    });

    test('isEmptyHtmlContent returns true for whitespace only', () {
      expect(isEmptyHtmlContent('   \n\t  '), true);
    });

    test('isEmptyHtmlContent returns true for single <br> tag', () {
      expect(isEmptyHtmlContent('<br>'), true);
    });

    test('isEmptyHtmlContent returns true for self-closing <br/> tag', () {
      expect(isEmptyHtmlContent('<br/>'), true);
    });

    test('isEmptyHtmlContent returns true for <br /> with spaces', () {
      expect(isEmptyHtmlContent('<br />'), true);
    });

    test('isEmptyHtmlContent returns true for empty paragraph', () {
      expect(isEmptyHtmlContent('<p></p>'), true);
    });

    test('isEmptyHtmlContent returns true for paragraph with whitespace', () {
      expect(isEmptyHtmlContent('<p>   </p>'), true);
    });

    test('isEmptyHtmlContent returns true for paragraph with &nbsp;', () {
      expect(isEmptyHtmlContent('<p>&nbsp;</p>'), true);
    });

    test('isEmptyHtmlContent returns true for paragraph with &#160;', () {
      expect(isEmptyHtmlContent('<p>&#160;</p>'), true);
    });

    test('isEmptyHtmlContent returns true for paragraph with <br>', () {
      expect(isEmptyHtmlContent('<p><br></p>'), true);
    });

    test('isEmptyHtmlContent returns true for paragraph with multiple <br>', () {
      expect(isEmptyHtmlContent('<p><br><br/></p>'), true);
    });

    test('isEmptyHtmlContent returns true for empty div', () {
      expect(isEmptyHtmlContent('<div></div>'), true);
    });

    test('isEmptyHtmlContent returns true for empty span', () {
      expect(isEmptyHtmlContent('<span></span>'), true);
    });

    test('isEmptyHtmlContent returns true for empty headings', () {
      expect(isEmptyHtmlContent('<h1></h1>'), true);
      expect(isEmptyHtmlContent('<h2>&nbsp;</h2>'), true);
      expect(isEmptyHtmlContent('<h6>   </h6>'), true);
    });

    test('isEmptyHtmlContent returns true for empty formatting tags', () {
      expect(isEmptyHtmlContent('<strong></strong>'), true);
      expect(isEmptyHtmlContent('<b>&nbsp;</b>'), true);
      expect(isEmptyHtmlContent('<em>   </em>'), true);
      expect(isEmptyHtmlContent('<i></i>'), true);
    });

    test('isEmptyHtmlContent returns true for empty list tags', () {
      expect(isEmptyHtmlContent('<ul></ul>'), true);
      expect(isEmptyHtmlContent('<ol></ol>'), true);
      expect(isEmptyHtmlContent('<li></li>'), true);
    });

    test('isEmptyHtmlContent returns true for multiple empty tags', () {
      expect(isEmptyHtmlContent('<p></p><br><div>&nbsp;</div>'), true);
    });

    test('isEmptyHtmlContent returns false for paragraph with actual content', () {
      expect(isEmptyHtmlContent('<p>Hello World</p>'), false);
    });

    test('isEmptyHtmlContent returns false for formatted content', () {
      expect(isEmptyHtmlContent('<p><strong>Hello</strong> World</p>'), false);
    });

    test('isEmptyHtmlContent returns false for content with line breaks', () {
      expect(isEmptyHtmlContent('<p>Hello<br>World</p>'), false);
    });

    test('isEmptyHtmlContent returns false for list with content', () {
      expect(isEmptyHtmlContent('<ul><li>Item 1</li></ul>'), false);
    });
  });

  group('Editor Content Validation', () {
    test('returns false when both plain text and HTML are empty', () {
      expect(
        hasValidEditorContent(plainText: '', html: ''),
        false,
      );
    });

    test('returns false when both plain text and HTML are whitespace', () {
      expect(
        hasValidEditorContent(plainText: '   ', html: '  '),
        false,
      );
    });

    test('returns true when plain text is empty but HTML has content', () {
      expect(
        hasValidEditorContent(plainText: '', html: '<p>Some content</p>'),
        true,
      );
    });

    test('returns true when plain text has content but HTML is empty', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: ''),
        true,
      );
    });

    test('returns true when plain text is whitespace and HTML has content', () {
      expect(
        hasValidEditorContent(plainText: '   ', html: '<p>Some content</p>'),
        true,
      );
    });

    test('returns true when plain text has content but HTML is only empty tags', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<br>'),
        true,
      );
    });

    test('returns true when HTML contains only empty paragraph but plainText has content', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p></p>'),
        true,
      );
    });

    test('returns true when HTML contains only whitespace in paragraph but plainText has content', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p>   </p>'),
        true,
      );
    });

    test('returns true when HTML contains only &nbsp; but plainText has content', () {
      expect(
        hasValidEditorContent(plainText: 'Some text', html: '<p>&nbsp;</p>'),
        true,
      );
    });

    test('returns true when HTML contains multiple empty tags but plainText has content', () {
      expect(
        hasValidEditorContent(
          plainText: 'Some text', 
          html: '<p></p><br><div>&nbsp;</div>',
        ),
        true,
      );
    });

    test('returns false when plainText is whitespace and HTML is empty', () {
      expect(
        hasValidEditorContent(plainText: '   \n\t  ', html: ''),
        false,
      );
    });

    test('returns false when plainText is whitespace and HTML has only empty tags', () {
      expect(
        hasValidEditorContent(plainText: '   ', html: '<p></p><br>'),
        false,
      );
    });

    test('returns false when both have only whitespace/empty content', () {
      expect(
        hasValidEditorContent(plainText: ' \t\n ', html: '<p>&nbsp;</p>'),
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

  group('Empty HTML Tags Regex', () {
    test('matches single <br> tag', () {
      expect(emptyHtmlTagsRegex.hasMatch('<br>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<br/>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<br />'), true);
    });

    test('matches empty paragraph tags', () {
      expect(emptyHtmlTagsRegex.hasMatch('<p></p>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<p> </p>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<p>&nbsp;</p>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<p>&#160;</p>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<p><br></p>'), true);
    });

    test('matches empty container tags', () {
      expect(emptyHtmlTagsRegex.hasMatch('<div></div>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<span></span>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<div>&nbsp;</div>'), true);
    });

    test('matches empty formatting tags', () {
      expect(emptyHtmlTagsRegex.hasMatch('<strong></strong>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<b></b>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<em></em>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<i></i>'), true);
    });

    test('matches empty list tags', () {
      expect(emptyHtmlTagsRegex.hasMatch('<ul></ul>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<ol></ol>'), true);
      expect(emptyHtmlTagsRegex.hasMatch('<li></li>'), true);
    });

    test('does not match tags with actual content', () {
      expect(emptyHtmlTagsRegex.hasMatch('<p>Hello</p>'), false);
      expect(emptyHtmlTagsRegex.hasMatch('<div>Content</div>'), false);
      expect(emptyHtmlTagsRegex.hasMatch('<strong>Bold text</strong>'), false);
    });

    test('can replace all empty tags in a string', () {
      const input = '<p></p><br><div>&nbsp;</div><span>Content</span>';
      final result = input.replaceAll(emptyHtmlTagsRegex, '');
      expect(result, '<span>Content</span>');
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
