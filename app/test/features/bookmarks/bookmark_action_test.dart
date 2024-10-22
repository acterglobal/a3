import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/bookmarks/widgets/bookmark_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/error_helpers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('BookmarkAction', () {
    testWidgets('set bookmark', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          isBookmarkedProvider.overrideWith((a, b) => false),
        ],
        child: const BookmarkAction(
          bookmarker: (id: 'a', type: BookmarkType.news),
        ),
      );
      final bookmarkKey = const ValueKey('a-bookmark');

      expect(find.byKey(bookmarkKey), findsOneWidget);
      // tester.tap(find.byKey(bookmarkKey));
    });
  });
}
