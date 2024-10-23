import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/bookmarks/widgets/bookmark_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mock_bookmarks.dart';
import '../../helpers/test_util.dart';

void main() {
  group('BookmarkAction', () {
    testWidgets('set bookmark', (tester) async {
      final mockManager = MockedBookmarksManager();
      when(() => mockManager.add(any(), any())).thenAnswer((a) async => true);
      await tester.pumpProviderWidget(
        overrides: [
          isBookmarkedProvider.overrideWith((ref, b) => false),
          bookmarksManagerProvider.overrideWith(
            () => MockBookmarksManagerNotifier(manager: mockManager),
          ),
        ],
        child: const BookmarkAction(
          bookmarker: (id: 'a', type: BookmarkType.news),
        ),
      );
      const bookmarkKey = ValueKey('a-bookmark');

      verifyNever(() => mockManager.add(any(), any()));

      expect(find.byKey(bookmarkKey), findsOneWidget);
      await tester.tap(find.byKey(bookmarkKey));
      await tester.pump();
      verify(() => mockManager.add(any(), any())).called(1);
    });
    testWidgets('unset bookmark', (tester) async {
      final mockManager = MockedBookmarksManager();
      when(() => mockManager.remove(any(), any()))
          .thenAnswer((a) async => true);
      await tester.pumpProviderWidget(
        overrides: [
          isBookmarkedProvider.overrideWith((ref, b) => true),
          bookmarksManagerProvider.overrideWith(
            () => MockBookmarksManagerNotifier(manager: mockManager),
          ),
        ],
        child: const BookmarkAction(
          bookmarker: (id: 'a', type: BookmarkType.news),
        ),
      );
      const unbookmarkKey = ValueKey('a-unbookmark');

      verifyNever(() => mockManager.add(any(), any()));

      expect(find.byKey(unbookmarkKey), findsOneWidget);
      await tester.tap(find.byKey(unbookmarkKey));
      await tester.pump();
      verify(() => mockManager.remove(any(), any())).called(1);
    });
  });
}
