import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/html/render_html_ng.dart';
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
}
