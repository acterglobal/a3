import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/html/render_html_ng.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/font_loader.dart';
import '../../helpers/test_util.dart';

void main() {
  group('HTML user Rendering Tests', () {
    testWidgets('renders matrix-to format', (tester) async {
      final html =
          'abcd <a href="https://matrix.to/#/@test:example.com">@test</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsOneWidget);
      expect(find.byType(RoomChip), findsNothing);
    });

    testWidgets('renders matrix: format', (tester) async {
      final html = 'abcd <a href="matrix:u/test:example.com">@test</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsOneWidget);
      expect(find.byType(RoomChip), findsNothing);
    });

    testWidgets('renders acter: format', (tester) async {
      final html = 'abcd <a href="acter:u/test:example.com">@test</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsOneWidget);
      expect(find.byType(RoomChip), findsNothing);
    });
  });

  group('HTML Room Rendering Tests', () {
    testWidgets('renders matrix-to format', (tester) async {
      final html =
          'abcd <a href="https://matrix.to/#/!test:example.com">!test:example.com</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(RoomChip), findsOneWidget);
      expect(find.byType(UserChip), findsNothing);
    });

    testWidgets('renders matrix: format', (tester) async {
      final html =
          'abcd <a href="matrix:roomid/test:example.com">!test:example.com</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(RoomChip), findsOneWidget);
      expect(find.byType(UserChip), findsNothing);
    });

    testWidgets('renders acter: format', (tester) async {
      final html =
          'abcd <a href="acter:roomid/test:example.com">!test:example.com</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(RoomChip), findsOneWidget);
      expect(find.byType(UserChip), findsNothing);
    });
  });

  group('HTML object Rendering Tests', () {
    testWidgets('renders pin', (tester) async {
      await loadTestFonts();
      final html =
          'abcd <a href="acter:o/room:acter.global/pin/pinId">\$pinId</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsNothing);
      expect(find.byType(RoomChip), findsNothing);
      expect(find.byType(InlineItemPreview), findsOneWidget);
      expect(
        find.byType(RenderHtmlNg),
        matchesGoldenFile('goldens/html_rendering_ng_pin.png'),
      );
    });
    testWidgets('renders calendar event', (tester) async {
      await loadTestFonts();
      final html =
          'abcd <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId">\$spaceObjectId</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsNothing);
      expect(find.byType(RoomChip), findsNothing);
      expect(find.byType(InlineItemPreview), findsOneWidget);
      expect(
        find.byType(RenderHtmlNg),
        matchesGoldenFile('goldens/html_rendering_ng_calendar_event.png'),
      );
    });
    testWidgets('renders when title only', (tester) async {
      await loadTestFonts();
      final html =
          'abcd <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId?title=Code+of+Conduct">Code of Conduct</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsNothing);
      expect(find.byType(RoomChip), findsNothing);
      expect(find.byType(InlineItemPreview), findsOneWidget);
      expect(
        find.byType(RenderHtmlNg),
        matchesGoldenFile('goldens/html_rendering_ng_title_only.png'),
      );
    });
  });

  group('HTML many Rendering Tests', () {
    testWidgets('renders many', (tester) async {
      await loadTestFonts();
      final html = '''
      dfg
      <a href="https://matrix.to/#/@peter:example.com">@peter:example.com</a>, <a href="matrix:u/test:example.com">@test:example.com</a>
      abcd <a href="matrix:roomid/test:example.com">!test:example.com</a>
      <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId?title=First+Meeting">🗓️ First Meeting</a>
      <a href="https://app.m-1.acter.global/p/575a56765ae0ee8630c62eb15e463c60a0978c1f?roomDisplayName=Kigis+Climate+Action+Group&title=Code+of+Conduct&via=%5B%27m-1.acter.global%27%5D&userId=jackie%3Am-1.acter.global#o/PIcnDNIUnpLcoFXnHf:m-1.acter.global/pin/AyCnLZVXNFC8rZDxsjy8RFlDcRmlgtT_ehkClxOyUYA">Code of Conduct</a>
      <a href="matrix:roomid/room2:example.com?title=Room+2">Room 2</a>  <a href="acter:o/room:acter.global/pin/pinId">\$pinId</a> 
      end''';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsExactly(2));
      expect(find.byType(RoomChip), findsExactly(2));
      expect(find.byType(InlineItemPreview), findsExactly(3));
      expect(
        find.byType(RenderHtmlNg),
        matchesGoldenFile('goldens/html_rendering_ng_many.png'),
      );
    });

    testWidgets('accepts renamed objects', (tester) async {
      await loadTestFonts();
      final html = '''
      dfg
      <a href="matrix:u/peter:example.com">@mr peter</a>, <a href="matrix:u/test:example.com">other username</a>
      abcd <a href="matrix:roomid/test:example.com">#test</a>
      <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId">this event</a>
      <a href="matrix:roomid/room2:example.com">this room</a>  <a href="acter:o/room:acter.global/pin/pinId">this pin</a> 
      end''';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsExactly(2));
      expect(find.byType(RoomChip), findsExactly(2));
      expect(find.byType(InlineItemPreview), findsExactly(2));
      expect(
        find.byType(RenderHtmlNg),
        matchesGoldenFile(
          'goldens/html_rendering_ng_accepts_renamed_objects.png',
        ),
      );
    });
  });
}
