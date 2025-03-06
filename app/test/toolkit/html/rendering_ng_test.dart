import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/html/render_html_ng.dart';
import 'package:acter/features/deep_linking/widgets/inline_item_preview.dart';
import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:flutter_test/flutter_test.dart';

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
          'abcd <a href="https://matrix.to/#/!test:example.com">!test</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(RoomChip), findsOneWidget);
      expect(find.byType(UserChip), findsNothing);
    });

    testWidgets('renders matrix: format', (tester) async {
      final html =
          'abcd <a href="matrix:roomid/test:example.com">!test</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(RoomChip), findsOneWidget);
      expect(find.byType(UserChip), findsNothing);
    });

    testWidgets('renders acter: format', (tester) async {
      final html = 'abcd <a href="acter:roomid/test:example.com">!test</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(RoomChip), findsOneWidget);
      expect(find.byType(UserChip), findsNothing);
    });
  });

  group('HTML object Rendering Tests', () {
    testWidgets('renders pin', (tester) async {
      final html =
          'abcd <a href="acter:o/room:acter.global/pin/pinId">@test</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsNothing);
      expect(find.byType(RoomChip), findsNothing);
      expect(find.byType(InlineItemPreview), findsOneWidget);
    });
    testWidgets('renders calendar event', (tester) async {
      final html =
          'abcd <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId">@test</a> end';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsNothing);
      expect(find.byType(RoomChip), findsNothing);
      expect(find.byType(InlineItemPreview), findsOneWidget);
    });
  });

  group('HTML many Rendering Tests', () {
    testWidgets('renders many', (tester) async {
      final html = '''
      dfg
      <a href="matrix:u/peter:example.com">@peter</a>, <a href="matrix:u/test:example.com">@test</a>
      abcd <a href="matrix:roomid/test:example.com">!test</a>
      <a href="acter:o/somewhere:example.org/calendarEvent/spaceObjectId">@test</a>
      <a href="matrix:roomid/room2:example.com">!room2</a>  <a href="acter:o/room:acter.global/pin/pinId">@test</a> 
      end''';

      await tester.pumpProviderWidget(
        child: RenderHtmlNg(text: html, roomId: 'test'),
      );

      expect(find.byType(UserChip), findsExactly(2));
      expect(find.byType(RoomChip), findsExactly(2));
      expect(find.byType(InlineItemPreview), findsExactly(2));
    });
  });
}
