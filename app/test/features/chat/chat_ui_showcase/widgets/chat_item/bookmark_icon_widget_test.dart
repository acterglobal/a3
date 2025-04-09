import 'package:acter/features/chat_ui_showcase/widgets/chat_item/bookmark_icon_widget.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../helpers/test_util.dart';

void main() {
  group('BookmarkIconWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      bool isBookmarked = true,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          isConvoBookmarked.overrideWith((a, b) => isBookmarked),
          roomDisplayNameProvider.overrideWith((a, b) => 'Space Name'),
        ],
        child: BookmarkIconWidget(roomId: 'mock-room-1'),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show bookmark icon when room is bookmarked', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, isBookmarked: true);
      expect(find.byIcon(PhosphorIcons.bookmarkSimple()), findsOneWidget);
    });

    testWidgets('should not show bookmark icon when room is not bookmarked', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, isBookmarked: false);
      expect(find.byIcon(PhosphorIcons.bookmarkSimple()), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
