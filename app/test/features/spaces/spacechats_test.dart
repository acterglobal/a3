import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:acter/features/chat/pages/sub_chats_page.dart';
import 'package:acter/features/space/widgets/space_info.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/features/space/widgets/space_sections/other_chats_section.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_room_providers.dart';
import '../../helpers/mock_space_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  List<Override> spaceOverrides() => [
        // mocking so we can display the page in general
        roomVisibilityProvider.overrideWith((a, b) => null),
        roomDisplayNameProvider.overrideWith((a, b) => null),
        parentAvatarInfosProvider.overrideWith((a, b) => []),
        roomAvatarProvider.overrideWith((a, b) => null),
        membersIdsProvider.overrideWith((a, b) => []),
        roomAvatarInfoProvider.overrideWith(() => MockRoomAvatarInfoNotifier()),
        roomMembershipProvider.overrideWith((a, b) => null),
        isBookmarkedProvider.overrideWith((a, b) => false),
        spaceInvitedMembersProvider.overrideWith((a, b) => []),
        shouldShowSuggestedProvider.overrideWith((a, b) => false),
        isActerSpaceForSpace.overrideWith((a, b) => false),
        suggestedSpacesProvider.overrideWith((a, b) async {
          return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
        }),
      ];

  group('Spacechats Page unaccessible items', () {
    testWidgets('Known show only', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          ...spaceOverrides(),
          spaceRemoteRelationsProvider.overrideWith((a, b) => []),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) => SpaceRelationsOverview(
              parents: [],
              knownChats: ['b', 'c'],
              knownSubspaces: [], // those are known
              otherRelations: [],
              mainParent: null,
              hasMore: false,
              suggestedIds: [],
            ),
          ),
          localCategoryListProvider.overrideWith(
            (a, b) => CategoryUtils().getCategorisedList(
              [],
              ['a', 'b', 'c'], // uncategorized subspaces
            ),
          ),

          // the actual failing ones
          spaceProvider.overrideWith((a, b) => MockSpace()),
        ],
        child: const SubChatsPage(spaceId: '!spaceId'),
      );

      // a doesn't show, b and c do because they are known
      expect(find.byType(RoomCard), findsExactly(2));
    });

    testWidgets('Unaccessible not shown', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          ...spaceOverrides(),
          spaceRelationsProvider.overrideWith((a, b) => null), // no remote
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) => SpaceRelationsOverview(
              parents: [],
              knownChats: [],
              knownSubspaces: [], // those aren't known
              otherRelations: [],
              mainParent: null,
              hasMore: false,
              suggestedIds: [],
            ),
          ),
          localCategoryListProvider.overrideWith(
            (a, b) => CategoryUtils().getCategorisedList(
              [],
              ['a', 'b', 'c'], // uncategorized subspaces
            ),
          ),

          // the actual failing ones
          spaceProvider.overrideWith((a, b) => MockSpace()),
        ],
        child: const SubChatsPage(spaceId: '!spaceId'),
      );

      // None of the items are accessible, do not show
      expect(find.byType(RoomCard), findsNothing);
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('Remote is shown, too', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          ...spaceOverrides(),
          maybeRoomProvider.overrideWith(() => MockAsyncMaybeRoomNotifier()),
          suggestedSpacesProvider.overrideWith((a, b) async {
            return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
          }),
          roomHierarchyAvatarProvider.overrideWith((a, b) => null),
          remoteChatRelationsProvider.overrideWith(
            (a, b) => [
              MockSpaceHierarchyRoomInfo(roomId: 'c', joinRule: 'Public'),
            ],
          ),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) => SpaceRelationsOverview(
              parents: [],
              knownChats: ['b'],
              knownSubspaces: [], // those are known, 'c' is a known remote one
              otherRelations: [],
              mainParent: null,
              hasMore: false,
              suggestedIds: [],
            ),
          ),
          localCategoryListProvider.overrideWith(
            (a, b) => CategoryUtils().getCategorisedList(
              [],
              ['a', 'b', 'c'], // uncategorized subspaces
            ),
          ),

          // the actual failing ones
          spaceProvider.overrideWith((a, b) => MockSpace()),
        ],
        child: const SubChatsPage(spaceId: '!spaceId'),
      );

      // a doesn't show, b and c do
      expect(find.byType(RoomCard), findsExactly(1));
      expect(find.byType(RoomHierarchyCard), findsExactly(1));
    });
  });

  group('Space Chat Overview Section unaccessible items', () {
    testWidgets('Known show only', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          ...spaceOverrides(),
          spaceRemoteRelationsProvider.overrideWith((a, b) => []),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) => SpaceRelationsOverview(
              parents: [],
              knownChats: ['b', 'c'],
              knownSubspaces: [], // those are known
              otherRelations: [],
              mainParent: null,
              hasMore: false,
              suggestedIds: [],
            ),
          ),
          localCategoryListProvider.overrideWith(
            (a, b) => CategoryUtils().getCategorisedList(
              [],
              ['a', 'b', 'c'], // uncategorized subspaces
            ),
          ),

          // the actual failing ones
          spaceProvider.overrideWith((a, b) => MockSpace()),
        ],
        child: const OtherChatsSection(spaceId: '!spaceId', limit: 3),
      );

      // a doesn't show, b and c do because they are known
      expect(find.byType(RoomCard), findsExactly(2));
    });

    testWidgets('Unaccessible not shown', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          ...spaceOverrides(),
          spaceRelationsProvider.overrideWith((a, b) => null), // no remote
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) => SpaceRelationsOverview(
              parents: [],
              knownChats: [],
              knownSubspaces: [], // those aren't known
              otherRelations: [],
              mainParent: null,
              hasMore: false,
              suggestedIds: [],
            ),
          ),
          localCategoryListProvider.overrideWith(
            (a, b) => CategoryUtils().getCategorisedList(
              [],
              ['a', 'b', 'c'], // uncategorized subspaces
            ),
          ),

          // the actual failing ones
          spaceProvider.overrideWith((a, b) => MockSpace()),
        ],
        child: const OtherChatsSection(spaceId: '!spaceId', limit: 3),
      );

      // None of the items are accessible, do not show
      expect(find.byType(RoomCard), findsNothing);
      expect(find.byType(RoomHierarchyCard), findsNothing);
    });

    testWidgets('Remote is shown, too', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          ...spaceOverrides(),
          maybeRoomProvider.overrideWith(() => MockAsyncMaybeRoomNotifier()),
          suggestedSpacesProvider.overrideWith((a, b) async {
            return (List<String>.empty(), List<SpaceHierarchyRoomInfo>.empty());
          }),
          roomHierarchyAvatarProvider.overrideWith((a, b) => null),
          remoteChatRelationsProvider.overrideWith(
            (a, b) => [
              MockSpaceHierarchyRoomInfo(roomId: 'c', joinRule: 'Public'),
            ],
          ),
          spaceRelationsOverviewProvider.overrideWith(
            (a, b) => SpaceRelationsOverview(
              parents: [],
              knownChats: ['b'],
              knownSubspaces: [], // those are known, 'c' is a known remote one
              otherRelations: [],
              mainParent: null,
              hasMore: false,
              suggestedIds: [],
            ),
          ),
          localCategoryListProvider.overrideWith(
            (a, b) => CategoryUtils().getCategorisedList(
              [],
              ['a', 'b', 'c'], // uncategorized subspaces
            ),
          ),

          // the actual failing ones
          spaceProvider.overrideWith((a, b) => MockSpace()),
        ],
        child: const OtherChatsSection(spaceId: '!spaceId', limit: 3),
      );

      // a doesn't show, b and c do
      expect(find.byType(RoomCard), findsExactly(1));
      expect(find.byType(RoomHierarchyCard), findsExactly(1));
    });
  });
}
