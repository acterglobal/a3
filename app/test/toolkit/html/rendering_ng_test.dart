import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/html/render_html_ng.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrk_flutter_test_batteries/hrk_flutter_test_batteries.dart';

import '../../helpers/font_loader.dart';
import '../../helpers/test_util.dart';

void main() {
  group('HTML Rendering NG Tests', () {
    setUp(() async {
      await loadTestFonts();

      useGoldenFileComparatorWithThreshold(0.01); // 1%
    });
    group('user rendering', () {
      testWidgets('renders matrix-to format', (tester) async {
        final html =
            'abcd <a href="https://matrix.to/#/@test:example.com">@test</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsOneWidget);
        expect(find.byType(RoomChip), findsNothing);
      });

      testWidgets('renders matrix: format', (tester) async {
        final html = 'abcd <a href="matrix:u/test:example.com">@test</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsOneWidget);
        expect(find.byType(RoomChip), findsNothing);
      });

      testWidgets('renders acter: format', (tester) async {
        final html = 'abcd <a href="acter:u/test:example.com">@test</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsOneWidget);
        expect(find.byType(RoomChip), findsNothing);
      });
    });

    group('room rendering', () {
      testWidgets('renders matrix-to format', (tester) async {
        final html =
            'abcd <a href="https://matrix.to/#/!test:example.com">!test:example.com</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(RoomChip), findsOneWidget);
        expect(find.byType(UserChip), findsNothing);
      });

      testWidgets('renders matrix: format', (tester) async {
        final html =
            'abcd <a href="matrix:roomid/test:example.com">!test:example.com</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(RoomChip), findsOneWidget);
        expect(find.byType(UserChip), findsNothing);
      });

      testWidgets('renders acter: format', (tester) async {
        final html =
            'abcd <a href="acter:roomid/test:example.com">!test:example.com</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(RoomChip), findsOneWidget);
        expect(find.byType(UserChip), findsNothing);
      });
    });

    group('objects rendering', () {
      testWidgets('renders pin', (tester) async {
        final html =
            'abcd <a href="acter:o/room:acter.global/pin/pinId">\$pinId</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsNothing);
        expect(find.byType(RoomChip), findsNothing);
        expect(find.byType(InlineItemPreview), findsOneWidget);
        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_pin.png'),
        );
      });
      testWidgets('renders calendar event without title', (tester) async {
        final html =
            'abcd <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId">\$spaceObjectId</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsNothing);
        expect(find.byType(RoomChip), findsNothing);
        expect(find.byType(InlineItemPreview), findsOneWidget);
        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_calendar_event.png'),
        );
      });
      testWidgets('renders when title only', (tester) async {
        final html =
            'abcd <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId?title=Code+of+Conduct">Code of Conduct</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsNothing);
        expect(find.byType(RoomChip), findsNothing);
        expect(find.byType(InlineItemPreview), findsOneWidget);
        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_title_only.png'),
        );
      });
    });
    group('regular links', () {
      testWidgets('renders regular links', (tester) async {
        final html =
            'abcd <a href="https://acter.global">acter.global regular link</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsExactly(0));
        expect(find.byType(RoomChip), findsExactly(0));
        expect(find.byType(InlineItemPreview), findsExactly(0));
        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_regular_links.png'),
        );
      });
      testWidgets('renders regular links in custom color and decoration', (
        tester,
      ) async {
        useGoldenFileComparatorWithThreshold(
          0.0, // 0% -- we must be picky to fail
        );
        final html =
            'abcd <a href="https://acter.global">acter.global regular link</a> end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(
            html: html,
            roomId: 'test',
            linkTextStyle: const TextStyle(
              color: Colors.green,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        );

        expect(find.byType(UserChip), findsExactly(0));
        expect(find.byType(RoomChip), findsExactly(0));
        expect(find.byType(InlineItemPreview), findsExactly(0));
        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile(
            'goldens/html_rendering_ng_regular_links_custom_font.png',
          ),
        );
      });
    });

    group('text rendering', () {
      testWidgets('renders line breaks', (tester) async {
        final text =
            'abcd \n 1. something \n 2. something else \n 3. something more \n\n end';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg.text(text: text, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsExactly(0));
        expect(find.byType(RoomChip), findsExactly(0));
        expect(find.byType(InlineItemPreview), findsExactly(0));
        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_text_line_breaks.png'),
        );
      });
      group('autodetects links', () {
        testWidgets('renders regular links', (tester) async {
          final text = 'abcd https://acter.global end';

          await tester.pumpProviderWidget(
            child: RenderHtmlNg.text(text: text, roomId: 'test'),
          );

          expect(find.byType(UserChip), findsExactly(0));
          expect(find.byType(RoomChip), findsExactly(0));
          expect(find.byType(InlineItemPreview), findsExactly(0));
          await expectLater(
            find.byType(RenderHtmlNg),
            matchesGoldenFile(
              'goldens/html_rendering_ng_regular_autodetect_links.png',
            ),
          );
        });
        testWidgets('renders regular links in custom color and decoration', (
          tester,
        ) async {
          useGoldenFileComparatorWithThreshold(
            0.0, // 0% -- we must be picky to fail
          );
          final text = 'abcd https://acter.global end';

          await tester.pumpProviderWidget(
            child: RenderHtmlNg.text(
              text: text,
              roomId: 'test',
              linkTextStyle: const TextStyle(
                color: Colors.green,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          );

          expect(find.byType(UserChip), findsExactly(0));
          expect(find.byType(RoomChip), findsExactly(0));
          expect(find.byType(InlineItemPreview), findsExactly(0));
          await expectLater(
            find.byType(RenderHtmlNg),
            matchesGoldenFile(
              'goldens/html_rendering_ng_regular_autodetect_links_custom_font.png',
            ),
          );
        });

        testWidgets('renders matrix-to format', (tester) async {
          final text = 'abcd https://matrix.to/#/@test:example.com end';

          await tester.pumpProviderWidget(
            child: RenderHtmlNg.text(text: text, roomId: 'test'),
          );

          expect(find.byType(UserChip), findsOneWidget);
          expect(find.byType(RoomChip), findsNothing);
          await expectLater(
            find.byType(RenderHtmlNg),
            matchesGoldenFile(
              'goldens/html_rendering_ng_regular_autodetect_matrix_to.png',
            ),
          );
        });

        testWidgets('renders matrix: format', (tester) async {
          final text = 'abcd matrix:u/test:example.com end';

          await tester.pumpProviderWidget(
            child: RenderHtmlNg.text(text: text, roomId: 'test'),
          );

          // expect(find.byType(UserChip), findsOneWidget);
          // expect(find.byType(RoomChip), findsNothing);
          await expectLater(
            find.byType(RenderHtmlNg),
            matchesGoldenFile(
              'goldens/html_rendering_ng_regular_autodetect_matrix.png',
            ),
          );
        });

        testWidgets('renders acter: format', (tester) async {
          final text = 'abcd acter:u/test:example.com end';

          await tester.pumpProviderWidget(
            child: RenderHtmlNg.text(text: text, roomId: 'test'),
          );

          // expect(find.byType(UserChip), findsOneWidget);
          // expect(find.byType(RoomChip), findsNothing);
          await expectLater(
            find.byType(RenderHtmlNg),
            matchesGoldenFile(
              'goldens/html_rendering_ng_regular_autodetect_acter_user.png',
            ),
          );
        });
        testWidgets('renders pin', (tester) async {
          final text = 'abcd acter:o/room:acter.global/pin/pinId end';

          await tester.pumpProviderWidget(
            child: RenderHtmlNg.text(text: text, roomId: 'test'),
          );

          // expect(find.byType(UserChip), findsNothing);
          // expect(find.byType(RoomChip), findsNothing);
          // expect(find.byType(InlineItemPreview), findsOneWidget);
          await expectLater(
            find.byType(RenderHtmlNg),
            matchesGoldenFile(
              'goldens/html_rendering_ng_regular_autodetect_acter_pin.png',
            ),
          );
        });
        testWidgets('renders calendar event without title', (tester) async {
          final text =
              'abcd acter:o/somewhere:example.org/calendarEvent/spaceObjectId end';

          await tester.pumpProviderWidget(
            child: RenderHtmlNg.text(text: text, roomId: 'test'),
          );

          // expect(find.byType(UserChip), findsNothing);
          // expect(find.byType(RoomChip), findsNothing);
          // expect(find.byType(InlineItemPreview), findsOneWidget);
          await expectLater(
            find.byType(RenderHtmlNg),
            matchesGoldenFile(
              'goldens/html_rendering_ng_regular_autodetect_calendar_event.png',
            ),
          );
        });
        testWidgets('renders when title only', (tester) async {
          final text =
              'abcd acter:o/somewhere:example.org/calendarEvent/spaceObjectId?title=Code+of+Conduct end';

          await tester.pumpProviderWidget(
            child: RenderHtmlNg.text(text: text, roomId: 'test'),
          );

          // expect(find.byType(UserChip), findsNothing);
          // expect(find.byType(RoomChip), findsNothing);
          // expect(find.byType(InlineItemPreview), findsOneWidget);
          await expectLater(
            find.byType(RenderHtmlNg),
            matchesGoldenFile(
              'goldens/html_rendering_ng_regular_autodetect_title_only.png',
            ),
          );
        });
      });
    });

    group('many', () {
      testWidgets('renders many', (tester) async {
        final html = '''
      dfg
      <a href="https://matrix.to/#/@peter:example.com">@peter:example.com</a>, <a href="matrix:u/test:example.com">@test:example.com</a>
      abcd <a href="matrix:roomid/test:example.com">!test:example.com</a>
      <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId?title=First+Meeting">🗓️ First Meeting</a>
      <a href="https://app.m-1.acter.global/p/575a56765ae0ee8630c62eb15e463c60a0978c1f?roomDisplayName=Kigis+Climate+Action+Group&title=Code+of+Conduct&via=%5B%27m-1.acter.global%27%5D&userId=jackie%3Am-1.acter.global#o/PIcnDNIUnpLcoFXnHf:m-1.acter.global/pin/AyCnLZVXNFC8rZDxsjy8RFlDcRmlgtT_ehkClxOyUYA">Code of Conduct</a>
      <a href="matrix:roomid/room2:example.com?title=Room+2">Room 2</a>  <a href="acter:o/room:acter.global/pin/pinId">\$pinId</a> 
      end''';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsExactly(2));
        expect(find.byType(RoomChip), findsExactly(2));
        expect(find.byType(InlineItemPreview), findsExactly(3));
        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_many.png'),
        );
      });

      testWidgets('accepts renamed objects', (tester) async {
        final html = '''
      dfg
      <a href="matrix:u/peter:example.com">@mr peter</a>, <a href="matrix:u/test:example.com">other username</a>
      abcd <a href="matrix:roomid/test:example.com">#test</a>
      <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId">this event</a>
      <a href="matrix:roomid/room2:example.com">this room</a>  <a href="acter:o/room:acter.global/pin/pinId">this pin</a> 
      end''';

        await tester.pumpProviderWidget(
          child: RenderHtmlNg(html: html, roomId: 'test'),
        );

        expect(find.byType(UserChip), findsExactly(2));
        expect(find.byType(RoomChip), findsExactly(2));
        expect(find.byType(InlineItemPreview), findsExactly(2));
        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile(
            'goldens/html_rendering_ng_accepts_renamed_objects.png',
          ),
        );
      });
    });

    group('maxLines', () {
      testWidgets('renders many limits 2', (tester) async {
        final html = '''
      dfg
      lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam, quos. eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
      end''';
        await tester.pumpProviderWidget(
          child: Scaffold(
            body: RenderHtmlNg(html: html, roomId: 'test', maxLines: 2),
          ),
        );

        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_many_max_2_lines.png'),
        );
      });

      testWidgets('renders many limits 4', (tester) async {
        final html = '''
      dfg
      lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam, quos. eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
      end''';
        await tester.pumpProviderWidget(
          child: Scaffold(
            body: RenderHtmlNg(html: html, roomId: 'test', maxLines: 4),
          ),
        );

        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_many_max_4_lines.png'),
        );
      });

      testWidgets('one line', (tester) async {
        final html = '''
      dfg
      lorem ipsum dolor sit amet consectetur adipisicing elit. Quisquam, quos. eiusmod
      end''';

        await tester.pumpProviderWidget(
          child: Scaffold(
            body: RenderHtmlNg(html: html, roomId: 'test', maxLines: 2),
          ),
        );

        await expectLater(
          find.byType(RenderHtmlNg),
          matchesGoldenFile('goldens/html_rendering_ng_one_line_max_lines.png'),
        );
      });
    });
  });
}
