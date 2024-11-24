import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/room/brief_room_list_entry.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/common/widgets/search.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/space/actions/unlink_child_room.dart';
import 'package:acter/features/spaces/providers/space_list_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::link_room_sheet');

// ChildRoomType configures the sub child type of the `Spaces`
enum ChildRoomType {
  chat,
  space,
}

class LinkRoomPage extends ConsumerStatefulWidget {
  static const confirmJoinRuleUpdateKey = Key('link-room-confirm-join-rule');
  static const denyJoinRuleUpdateKey = Key('link-room-deny-join-rule');

  final String parentSpaceId;
  final ChildRoomType childRoomType;

  const LinkRoomPage({
    super.key,
    required this.parentSpaceId,
    required this.childRoomType,
  });

  @override
  ConsumerState<LinkRoomPage> createState() => _LinkRoomPageConsumerState();
}

typedef RoomQuery = ({String parentId, String childId});

final isSubChatProvider = StateProvider.family<bool, RoomQuery>(
  (ref, query) =>
      ref
          .watch(spaceRelationsOverviewProvider(query.parentId))
          .valueOrNull
          ?.knownChats
          .contains(query.childId) ==
      true,
);

final isSubSpaceProvider = StateProvider.family<bool, RoomQuery>(
  (ref, query) =>
      ref
          .watch(spaceRelationsOverviewProvider(query.parentId))
          .valueOrNull
          ?.knownSubspaces
          .contains(query.childId) ==
      true,
);

final isRecommendedProvider = StateProvider.family<bool, RoomQuery>(
  (ref, query) =>
      ref
          .watch(spaceRelationsOverviewProvider(query.parentId))
          .valueOrNull
          ?.otherRelations
          .map((x) => x.getRoomIdStr())
          .contains(query.childId) ==
      true,
);

class _LinkRoomPageConsumerState extends ConsumerState<LinkRoomPage> {
  final TextEditingController searchTextEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SliverScaffold(
      header: switch (widget.childRoomType) {
        ChildRoomType.chat => L10n.of(context).linkChat,
        ChildRoomType.space => L10n.of(context).linkSpace,
      },
      body: SizedBox(
        height: screenSize.height - 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            parentSpaceDataUI(),
            searchUI(),
            Expanded(
              child: widget.childRoomType == ChildRoomType.chat
                  ? chatsList()
                  : spacesList(),
            ),
          ],
        ),
      ),
    );
  }

//Search
  Widget searchUI() {
    return Search(
      onChanged: (value) {
        final notifier = ref.read(roomSearchValueProvider.notifier);
        notifier.update((state) => value);
      },
      searchController: searchTextEditingController,
    );
  }

//Parent space
  Widget parentSpaceDataUI() {
    final space = ref.watch(selectedSpaceDetailsProvider);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: space.map(
            (p0) => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context).parentSpace),
                SpaceChip(
                  spaceId: p0.roomId,
                  onTapOpenSpaceDetail: false,
                ),
              ],
            ),
          ) ??
          const SizedBox.shrink(),
    );
  }

//List of chats excluding DMs that can be linked according to the selected parent space
  Widget chatsList() {
    final searchValue = ref.watch(roomSearchValueProvider);
    if (searchValue?.isNotEmpty == true) {
      return searchedChatsList();
    }

    final chatList = ref.watch(
      chatsProvider.select(
        (rooms) => rooms
            .where((room) => (!room.isDm()))
            .map((r) => r.getRoomIdStr())
            .toList(),
      ),
    );
    return chatListUI(chatList);
  }

//Show chat list based on the search term
  Widget searchedChatsList() {
    final lang = L10n.of(context);
    final searchedList = ref.watch(roomSearchedChatsProvider);
    return searchedList.when(
      data: (chats) => chats.isEmpty
          ? Text(lang.noChatsFoundMatchingYourSearchTerm)
          : chatListUI(chats),
      error: (e, s) {
        _log.severe('Failed to search chats', e, s);
        return errorUI(lang.searchingFailed(e));
      },
      loading: () => loadingUI(),
    );
  }

//Chat List
  Widget chatListUI(List<String> chatList) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chatList.length,
      itemBuilder: (context, index) {
        final roomId = chatList[index];
        return BriefRoomEntry(
          roomId: roomId,
          canCheck: 'CanLinkSpaces',
          onSelect: null,
          keyPrefix: 'chat-list-link',
          trailingBuilder: (canLink) => Consumer(
            builder: (
              context,
              ref,
              child,
            ) =>
                _RoomTrailing(
              roomId: roomId,
              parentId: widget.parentSpaceId,
              isLinked: ref.watch(
                isSubChatProvider(
                  (parentId: widget.parentSpaceId, childId: roomId),
                ),
              ),
              canLink: canLink,
            ),
          ),
        );
      },
    );
  }

//List of spaces that can be linked according to the selected parent space
  Widget spacesList() {
    final searchValue = ref.watch(roomSearchValueProvider);
    if (searchValue?.isNotEmpty == true) {
      return searchedSpaceList();
    }

    final spaces = ref.watch(spacesProvider);
    return spaceListUI(spaces.map((space) => space.getRoomIdStr()).toList());
  }

//Show space list based on the search term
  Widget searchedSpaceList() {
    final lang = L10n.of(context);
    final searchedSpaces = ref.watch(searchedSpacesProvider);
    return searchedSpaces.when(
      data: (spaces) {
        if (spaces.isEmpty) {
          return Center(
            heightFactor: 10,
            child: Text(lang.noChatsFoundMatchingYourSearchTerm),
          );
        }
        return spaceListUI(spaces);
      },
      loading: () => loadingUI(),
      error: (e, s) {
        _log.severe('Failed to search spaces', e, s);
        return errorUI(lang.searchingFailed(e));
      },
    );
  }

//Space List
  Widget spaceListUI(List<String> spacesList) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: spacesList.length,
      itemBuilder: (context, index) => _SpaceListItem(
        parentId: widget.parentSpaceId,
        roomId: spacesList[index],
      ),
    );
  }

//Common loading UI
  Widget loadingUI() {
    return const Center(
      heightFactor: 10,
      child: CircularProgressIndicator(),
    );
  }

//Common error UI
  Widget errorUI(String message) {
    return Center(
      child: Text(message),
    );
  }
}

class _SpaceListItem extends ConsumerWidget {
  final String parentId;
  final String roomId;
  const _SpaceListItem({
    required this.parentId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (parentId: parentId, childId: roomId);
    final isSubspace = ref.watch(isSubSpaceProvider(query));
    final isRecommended = ref.watch(isRecommendedProvider(query));
    final isLinked = isSubspace || isRecommended;

    final subtitle = isSubspace
        ? Text(L10n.of(context).subspace)
        : isRecommended
            ? Text(L10n.of(context).recommendedSpace)
            : null;

    final roomName =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? roomId;

    return ListTile(
      key: Key('space-list-link-$roomId'),
      leading: RoomAvatarBuilder(
        roomId: roomId,
        avatarSize: 24,
      ),
      title: Text(roomName),
      subtitle: subtitle,
      trailing: _RoomTrailing(
        parentId: parentId,
        roomId: roomId,
        isLinked: isLinked,
        canLink: true,
      ),
    );
  }
}

class _RoomTrailing extends ConsumerWidget {
  final bool canLink;
  final bool isLinked;
  final String parentId;
  final String roomId;

  const _RoomTrailing({
    required this.parentId,
    required this.roomId,
    required this.canLink,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 100,
      child: isLinked
          ? OutlinedButton(
              onPressed: () => onTapUnlinkChildRoom(context, ref),
              key: Key('room-list-unlink-$roomId'),
              child: Text(lang.unlink),
            )
          : canLink
              ? OutlinedButton(
                  onPressed: () => onTapLinkChildRoom(context, ref),
                  key: Key('room-list-link-$roomId'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.success),
                  ),
                  child: Text(lang.link),
                )
              : null,
    );
  }

  Future<void> checkJoinRule(
    BuildContext context,
    WidgetRef ref,
    Room room,
    String parentSpaceId,
  ) async {
    final lang = L10n.of(context);
    final joinRule = room.joinRuleStr();
    List<String> currentRooms = [];
    bool parentCanSee = joinRule == 'public';
    String newRule = 'restricted';
    if (joinRule == 'restricted' || joinRule == 'knock_restricted') {
      currentRooms = asDartStringList(room.restrictedRoomIdsStr());
      parentCanSee = currentRooms.contains(parentSpaceId);
      newRule = joinRule;
    }

    if (!parentCanSee) {
      final spaceAvatarInfo = ref.read(roomAvatarInfoProvider(parentSpaceId));
      final parentSpaceName =
          spaceAvatarInfo.displayName ?? lang.theParentSpace;
      final roomName =
          // ignore: use_build_context_synchronously
          spaceAvatarInfo.displayName ?? lang.theSelectedRooms;
      bool shouldChange = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(lang.notVisible),
            content: Wrap(
              children: [
                Text(
                  lang.theCurrentJoinRulesOfSpace(roomName, parentSpaceName),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: <Widget>[
              OutlinedButton(
                key: LinkRoomPage.denyJoinRuleUpdateKey,
                child: Text(lang.noThanks),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              ActerPrimaryActionButton(
                key: LinkRoomPage.confirmJoinRuleUpdateKey,
                child: Text(lang.yesPleaseUpdate),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          );
        },
      );
      if (shouldChange) {
        currentRooms.add(parentSpaceId);

        final sdk = await ref.read(sdkProvider.future);
        final update = sdk.api.newJoinRuleBuilder();
        update.joinRule(newRule);
        for (final roomId in currentRooms) {
          update.addRoom(roomId);
        }
        await room.setJoinRule(update);
      }
    }
  }

//Link child room
  Future<void> onTapLinkChildRoom(BuildContext context, WidgetRef ref) async {
    final upgradeConfiguration = true;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.read(spaceProvider(parentId).future);
    await space.addChildRoom(roomId, false);

    //Make subspace
    if (upgradeConfiguration) {
      //Fetch selected room data and add given parentSpaceId as parent
      final room = await ref.read(maybeRoomProvider(roomId).future);
      if (room != null) {
        await room.addParentRoom(parentId, true);
        if (!context.mounted) return;
        await checkJoinRule(context, ref, room, parentId);
      }
    }

    invalidateProviders(ref);
  }

//Unlink child room
  Future<void> onTapUnlinkChildRoom(BuildContext context, WidgetRef ref) async {
    await unlinkChildRoom(
      context,
      ref,
      parentId: parentId,
      roomId: roomId,
    );
    //Invalidate providers
    invalidateProviders(ref);
  }

  void invalidateProviders(WidgetRef ref) {
    //Invalidate providers
    ref.invalidate(spaceRelationsProvider(parentId));
    ref.invalidate(spaceRemoteRelationsProvider(parentId));
    ref.invalidate(subChatsListProvider(parentId));
    ref.invalidate(subSpacesListProvider(parentId));
    ref.invalidate(localCategoryListProvider);
  }
}
