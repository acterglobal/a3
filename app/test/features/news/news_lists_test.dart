import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/comments/providers/comments_providers.dart';
import 'package:acter/features/news/pages/news_list_page.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_skeleton_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mock_news_providers.dart';
import '../../helpers/test_util.dart';
import '../comments/mock_data/mock_message_content.dart';

void main() {
  group('News List fullView', () {
    testWidgets('displays empty state when there are no news', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          newsListProvider.overrideWith(() => MockAsyncNewsListNotifier()),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const NewsListPage(
          newsViewMode: NewsViewMode.fullView,
        ),
      );

      await tester.pump();

      expect(
        find.byType(EmptyState),
        findsOneWidget,
      ); // Ensure the empty state widget is displayed
    });
    testWidgets('Shows latest news', (tester) async {
      final slide = MockNewsSlide();
      when(() => slide.typeStr()).thenReturn('text');
      when(() => slide.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is an important news'));
      final entry = MockNewsEntry(slides_: [slide]);
      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((a) => 'my user id'),
          likedByMeProvider.overrideWith((a, b) => false),
          totalLikesForNewsProvider.overrideWith((a, b) => 0),
          newsCommentsCountProvider.overrideWith((a, b) => 0),
          roomDisplayNameProvider.overrideWith((a, b) => 'SpaceName'),
          briefSpaceItemProvider.overrideWith(
            (a, b) => SpaceItem(
              roomId: 'roomId',
              activeMembers: [],
              avatarInfo: AvatarInfo(uniqueId: 'id'),
            ),
          ),
          newsListProvider.overrideWith(
            () => MockAsyncNewsListNotifier(
              news: [
                entry, // the only one that matters
                MockNewsEntry(),
                MockNewsEntry(),
              ],
            ),
          ),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const NewsListPage(newsViewMode: NewsViewMode.fullView),
      );

      await tester.pump();

      expect(
        find.text('This is an important news'),
        findsOneWidget,
      ); // Ensure the empty state widget is displayed
    });

    testWidgets('Shows selected news', (tester) async {
      final slide = MockNewsSlide();
      when(() => slide.typeStr()).thenReturn('text');
      when(() => slide.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is an important news'));
      final entry1 = MockNewsEntry(slides_: [slide], eventId_: 'firstId');

      final slide2 = MockNewsSlide();
      when(() => slide2.typeStr()).thenReturn('text');
      when(() => slide2.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the second news'));
      final entry2 = MockNewsEntry(slides_: [slide2], eventId_: 'secondId');

      final slide3 = MockNewsSlide();
      when(() => slide3.typeStr()).thenReturn('text');
      when(() => slide3.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the third news'));
      final entry3 = MockNewsEntry(slides_: [slide3], eventId_: 'thirdId');
      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((a) => 'my user id'),
          likedByMeProvider.overrideWith((a, b) => false),
          totalLikesForNewsProvider.overrideWith((a, b) => 0),
          newsCommentsCountProvider.overrideWith((a, b) => 0),
          roomDisplayNameProvider.overrideWith((a, b) => 'SpaceName'),
          briefSpaceItemProvider.overrideWith(
            (a, b) => SpaceItem(
              roomId: 'roomId',
              activeMembers: [],
              avatarInfo: AvatarInfo(uniqueId: 'id'),
            ),
          ),
          newsListProvider.overrideWith(
            () => MockAsyncNewsListNotifier(
              news: [entry1, entry2, entry3],
            ),
          ),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const NewsListPage(
          newsViewMode: NewsViewMode.fullView,
          initialEventId: 'secondId',
        ),
      );

      await tester.pump();

      expect(
        find.text('This is the second news'),
        findsOneWidget,
      ); // Ensure the correct news widget is displayed
    });

    testWidgets('selected news appears later', (tester) async {
      final slide = MockNewsSlide();
      when(() => slide.typeStr()).thenReturn('text');
      when(() => slide.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is an important news'));
      final entry1 = MockNewsEntry(slides_: [slide], eventId_: 'firstId');

      final slide2 = MockNewsSlide();
      when(() => slide2.typeStr()).thenReturn('text');
      when(() => slide2.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the second news'));
      final entry2 = MockNewsEntry(slides_: [slide2], eventId_: 'secondId');

      final slide3 = MockNewsSlide();
      when(() => slide3.typeStr()).thenReturn('text');
      when(() => slide3.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the third news'));
      final entry3 = MockNewsEntry(slides_: [slide3], eventId_: 'thirdId');

      final slide4 = MockNewsSlide();
      when(() => slide4.typeStr()).thenReturn('text');
      when(() => slide4.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the fourth news'));
      final entry4 = MockNewsEntry(slides_: [slide4], eventId_: 'fourthId');

      final notifier = MockAsyncNewsListNotifier(
        news: [entry1, entry2, entry3],
      );
      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((a) => 'my user id'),
          likedByMeProvider.overrideWith((a, b) => false),
          totalLikesForNewsProvider.overrideWith((a, b) => 0),
          newsCommentsCountProvider.overrideWith((a, b) => 0),
          roomDisplayNameProvider.overrideWith((a, b) => 'SpaceName'),
          briefSpaceItemProvider.overrideWith(
            (a, b) => SpaceItem(
              roomId: 'roomId',
              activeMembers: [],
              avatarInfo: AvatarInfo(uniqueId: 'id'),
            ),
          ),
          newsListProvider.overrideWith(
            () => notifier,
          ),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const NewsListPage(
          newsViewMode: NewsViewMode.fullView,
          initialEventId: 'fourthId',
        ),
      );

      await tester.pump();

      expect(
        find.byType(NewsSkeletonWidget),
        findsOneWidget,
      ); // Ensure the loading is shown

      notifier.news!.add(entry4);
      notifier.ref.invalidateSelf(); // refresh

      await tester.pump();

      expect(
        find.text('This is the fourth news'),
        findsOneWidget,
      ); // Ensure the correct news widget is displayed
    });
  });
}
