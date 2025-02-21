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
import '../../helpers/mock_updates_providers.dart';
import '../../helpers/test_util.dart';
import '../comments/mock_data/mock_message_content.dart';

void main() {
  group('Updates List fullView', () {
    testWidgets('displays empty state when there are no Updates',
        (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          updateListProvider.overrideWith((ref, arg) async => []),
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
    testWidgets('Shows latest Updates', (tester) async {
      final slide = MockUpdateSlide();
      when(() => slide.typeStr()).thenReturn('text');
      when(() => slide.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is an important Updates'));
      final entry = MockUpdatesEntry(slides_: [slide]);
      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((a) => 'my user id'),
          likedByMeProvider.overrideWith((a, b) => false),
          totalLikesForNewsProvider.overrideWith((a, b) => 0),
          updateCommentsCountProvider.overrideWith((a, b) => 0),
          roomDisplayNameProvider.overrideWith((a, b) => 'SpaceName'),
          briefSpaceItemProvider.overrideWith(
            (a, b) => SpaceItem(
              roomId: 'roomId',
              activeMembers: [],
              avatarInfo: AvatarInfo(uniqueId: 'id'),
            ),
          ),
          updateListProvider.overrideWith(
            (ref, arg) async => [
              entry,
            ],
          ),
          hasSpaceWithPermissionProvider.overrideWith((_, ref) => false),
        ],
        child: const NewsListPage(newsViewMode: NewsViewMode.fullView),
      );

      await tester.pump();

      expect(
        find.text('This is an important Updates'),
        findsOneWidget,
      ); // Ensure the empty state widget is displayed
    });

    testWidgets('Shows selected Updates', (tester) async {
      final slide = MockUpdateSlide();
      when(() => slide.typeStr()).thenReturn('text');
      when(() => slide.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is an important Updates'));
      final entry1 = MockUpdatesEntry(slides_: [slide], eventId_: 'firstId');

      final slide2 = MockUpdateSlide();
      when(() => slide2.typeStr()).thenReturn('text');
      when(() => slide2.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the second Updates'));
      final entry2 = MockUpdatesEntry(slides_: [slide2], eventId_: 'secondId');

      final slide3 = MockUpdateSlide();
      when(() => slide3.typeStr()).thenReturn('text');
      when(() => slide3.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the third Updates'));
      final entry3 = MockUpdatesEntry(slides_: [slide3], eventId_: 'thirdId');
      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((a) => 'my user id'),
          likedByMeProvider.overrideWith((a, b) => false),
          totalLikesForNewsProvider.overrideWith((a, b) => 0),
          updateCommentsCountProvider.overrideWith((a, b) => 0),
          roomDisplayNameProvider.overrideWith((a, b) => 'SpaceName'),
          briefSpaceItemProvider.overrideWith(
            (a, b) => SpaceItem(
              roomId: 'roomId',
              activeMembers: [],
              avatarInfo: AvatarInfo(uniqueId: 'id'),
            ),
          ),
          updateListProvider.overrideWith(
            (ref, arg) async => [entry1, entry2, entry3],
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
        find.text('This is the second Updates'),
        findsOneWidget,
      ); // Ensure the correct Updates widget is displayed
    });

    testWidgets('selected Updates appears later', (tester) async {
      final slide = MockUpdateSlide();
      when(() => slide.typeStr()).thenReturn('text');
      when(() => slide.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is an important Updates'));
      final entry1 = MockUpdatesEntry(slides_: [slide], eventId_: 'firstId');

      final slide2 = MockUpdateSlide();
      when(() => slide2.typeStr()).thenReturn('text');
      when(() => slide2.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the second Updates'));
      final entry2 = MockUpdatesEntry(slides_: [slide2], eventId_: 'secondId');

      final slide3 = MockUpdateSlide();
      when(() => slide3.typeStr()).thenReturn('text');
      when(() => slide3.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the third Updates'));
      final entry3 = MockUpdatesEntry(slides_: [slide3], eventId_: 'thirdId');

      final slide4 = MockUpdateSlide();
      when(() => slide4.typeStr()).thenReturn('text');
      when(() => slide4.msgContent())
          .thenReturn(MockMsgContent(bodyText: 'This is the fourth Updates'));
      final entry4 = MockUpdatesEntry(slides_: [slide4], eventId_: 'fourthId');

      final updateEntries = [entry1, entry2, entry3];
      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((a) => 'my user id'),
          likedByMeProvider.overrideWith((a, b) => false),
          totalLikesForNewsProvider.overrideWith((a, b) => 0),
          updateCommentsCountProvider.overrideWith((a, b) => 0),
          roomDisplayNameProvider.overrideWith((a, b) => 'SpaceName'),
          briefSpaceItemProvider.overrideWith(
            (a, b) => SpaceItem(
              roomId: 'roomId',
              activeMembers: [],
              avatarInfo: AvatarInfo(uniqueId: 'id'),
            ),
          ),
          updateListProvider.overrideWith((ref, arg) async => updateEntries),
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
    });
  });
}
