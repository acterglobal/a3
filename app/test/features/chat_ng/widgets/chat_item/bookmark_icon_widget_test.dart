import 'package:acter/features/chat_ng/widgets/chat_item/bookmark_icon_widget.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../helpers/test_util.dart';

void main() {
  group('BookmarkIconWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      bool isBookmarked = true,
      bool isError = false,
      bool isLoading = false,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          isConvoBookmarked.overrideWith((a, b) {
            if (isLoading) {
              return Future.delayed(
                const Duration(milliseconds: 100),
                () => isBookmarked,
              );
            }
            if (isError) {
              return Future.error('Error');
            }
            return Future.value(isBookmarked);
          }),
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
      expect(
        find.byIcon(PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)),
        findsOneWidget,
      );
    });

    testWidgets('should not show bookmark icon when room is not bookmarked', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, isBookmarked: false);
      expect(
        find.byIcon(PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)),
        findsNothing,
      );
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should handle error case', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, isError: true);
      expect(
        find.byIcon(PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)),
        findsNothing,
      );
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should handle loading case', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        isLoading: true,
        isBookmarked: true,
      );

      expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsOneWidget);
      // Wait for the async provider to load
      await tester.pump(const Duration(milliseconds: 110));
      expect(
        find.byIcon(PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)),
        findsOneWidget,
      );
      expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsNothing);
    });
  });
}
