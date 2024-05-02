import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/room/brief_room_list_entry.dart';
import 'package:acter/common/widgets/search.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

// ChildRoomType configures the sub child type of the `Spaces`
enum ChildRoomType {
  chat,
  space,
  recommendedSpace,
}

class LinkRoomPage extends ConsumerStatefulWidget {
  final String parentSpaceId;
  final String pageTitle;
  final ChildRoomType childRoomType;

  static const confirmJoinRuleUpdateKey = Key('link-room-confirm-join-rule');
  static const denyJoinRuleUpdateKey = Key('link-room-deny-join-rule');

  const LinkRoomPage({
    super.key,
    required this.parentSpaceId,
    required this.pageTitle,
    required this.childRoomType,
  });

  @override
  ConsumerState<LinkRoomPage> createState() => _LinkRoomPageConsumerState();
}

class _LinkRoomPageConsumerState extends ConsumerState<LinkRoomPage> {
  final TextEditingController searchTextEditingController =
      TextEditingController();
  final List<String> childRoomsIds = [];
  final List<String> recommendedChildSpaceIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      selectParentSpaceData();
      fetchKnownSubChatsData();
    });
  }

//Select parent space data
  void selectParentSpaceData() {
    final notifier = ref.read(selectedSpaceIdProvider.notifier);
    notifier.state = widget.parentSpaceId;
  }

//Fetch known sub-rooms list of selected parent space
  void fetchKnownSubChatsData() async {
    final selectedParentSpaceId = ref.read(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;
    final space = await ref
        .read(spaceRelationsOverviewProvider(selectedParentSpaceId).future);

    childRoomsIds.clear();
    if (widget.childRoomType == ChildRoomType.chat) {
      for (int i = 0; i < space.knownChats.length; i++) {
        childRoomsIds.add(space.knownChats[i].getRoomIdStr());
      }
    } else {
      for (int i = 0; i < space.knownSubspaces.length; i++) {
        childRoomsIds.add(space.knownSubspaces[i].getRoomIdStr());
      }
      //Add recommended child spaces ids
      recommendedChildSpaceIds.clear();
      for (int i = 0; i < space.otherRelations.length; i++) {
        recommendedChildSpaceIds.add(space.otherRelations[i].getRoomIdStr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SliverScaffold(
      header: widget.pageTitle,
      body: SizedBox(
        height: size.height - 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            parentSpaceDataUI(),
            searchUI(),
            Expanded(child: roomList()),
          ],
        ),
      ),
    );
  }

//Search
  Widget searchUI() {
    return Search(
      onChanged: (value) {
        ref.read(roomSearchValueProvider.notifier).update((state) => value);
      },
      searchController: searchTextEditingController,
    );
  }

//Parent space
  Widget parentSpaceDataUI() {
    final spaceDetails = ref.watch(selectedSpaceDetailsProvider);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: spaceDetails.when(
        data: (space) {
          return space == null
              ? const SizedBox.shrink()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L10n.of(context).parentSpace),
                    SpaceChip(
                      space: space,
                      onTapOpenSpaceDetail: false,
                    ),
                  ],
                );
        },
        error: (e, s) => errorUI(L10n.of(context).error(e)),
        loading: () => Container(),
      ),
    );
  }

//Manage list data based on the child room type
  Widget roomList() {
    if (widget.childRoomType == ChildRoomType.chat) {
      return chatsList();
    } else {
      return spacesList();
    }
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
    final searchedList = ref.watch(roomSearchedChatsProvider);
    return searchedList.when(
      data: (chats) => chats.isEmpty
          ? Text(L10n.of(context).noChatsFoundMatchingYourSearchTerm)
          : chatListUI(chats),
      error: (e, s) => errorUI(L10n.of(context).searchingFailed(e)),
      loading: () => loadingUI(),
    );
  }

  bool isLinked(String roomId) {
    return childRoomsIds.contains(roomId);
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
          keyPrefix: 'room-list-link-',
          avatarDisplayMode: DisplayMode.GroupChat,
          trailingBuilder: (canLink) =>
              roomTrailing(roomId, isLinked(roomId), canLink),
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

    final spaces =
        ref.watch(spacesProvider).map((space) => space.getRoomIdStr()).toList();
    return spaceListUI(spaces);
  }

//Show space list based on the search term
  Widget searchedSpaceList() {
    final searchedSpaces = ref.watch(searchedSpacesProvider);
    return searchedSpaces.when(
      data: (spaces) {
        if (spaces.isEmpty) {
          return Center(
            heightFactor: 10,
            child: Text(L10n.of(context).noChatsFoundMatchingYourSearchTerm),
          );
        }
        return spaceListUI(spaces);
      },
      loading: () => loadingUI(),
      error: (e, s) => errorUI(L10n.of(context).searchingFailed(e)),
    );
  }

//Space List
  Widget spaceListUI(List<String> spacesList) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: spacesList.length,
      itemBuilder: (context, index) {
        final roomId = spacesList[index];
        final isSubspace = childRoomsIds.contains(roomId);
        final isLinked = widget.childRoomType == ChildRoomType.space
            ? childRoomsIds.contains(roomId)
            : recommendedChildSpaceIds.contains(roomId);

        final subtitle = isSubspace
            ? Text(L10n.of(context).subspace)
            : recommendedChildSpaceIds.contains(roomId)
                ? Text(L10n.of(context).recommendedSpace)
                : null;

        return BriefRoomEntry(
          avatarDisplayMode: DisplayMode.Space,
          roomId: roomId,
          canCheck: 'CanLinkSpaces',
          subtitle: subtitle,
          trailingBuilder: (canLink) => roomTrailing(
            roomId,
            isLinked,
            widget.childRoomType == ChildRoomType.recommendedSpace
                ? !isSubspace
                : canLink,
          ),
        );
      },
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

  Widget roomTrailing(String roomId, bool isLinked, bool canLink) {
    return SizedBox(
      width: 100,
      child: isLinked
          ? OutlinedButton(
              onPressed: () => onTapUnlinkChildRoom(roomId),
              key: Key('room-list-unlink-$roomId'),
              child: Text(L10n.of(context).unlink),
            )
          : canLink
              ? OutlinedButton(
                  onPressed: () => onTapLinkChildRoom(context, roomId),
                  key: Key('room-list-link-$roomId'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.success,
                    ),
                  ),
                  child: Text(L10n.of(context).link),
                )
              : null,
    );
  }

  Future<void> checkJoinRule(
    BuildContext context,
    Room room,
    String parentSpaceId,
  ) async {
    final joinRule = room.joinRuleStr();
    List<String> currentRooms = [];
    bool parentCanSee = joinRule == 'public';
    String newRule = 'restricted';
    if (joinRule == 'restricted' || joinRule == 'knock_restricted') {
      currentRooms =
          room.restrictedRoomIdsStr().map((t) => t.toString()).toList();
      parentCanSee = currentRooms.contains(parentSpaceId);
      newRule = joinRule;
    }

    if (!parentCanSee) {
      final spaceProfile = await ref
          .read(spaceProfileDataForSpaceIdProvider(parentSpaceId).future);
      final roomProfile =
          await ref.read(roomProfileDataProvider(room.roomIdStr()).future);
      if (!mounted) return;
      final parentSpaceName =
          // ignore: use_build_context_synchronously
          spaceProfile.profile.displayName ?? L10n.of(context).theParentSpace;
      final roomName =
          // ignore: use_build_context_synchronously
          roomProfile.displayName ?? L10n.of(context).theSelectedRooms;
      bool shouldChange = await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(L10n.of(context).notVisible),
            content: Wrap(
              children: [
                Text(
                  L10n.of(context)
                      .theCurrentJoinRulesOfSpace(roomName, parentSpaceName),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: <Widget>[
              OutlinedButton(
                key: LinkRoomPage.denyJoinRuleUpdateKey,
                child: Text(L10n.of(context).noThanks),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              ActerPrimaryActionButton(
                key: LinkRoomPage.confirmJoinRuleUpdateKey,
                child: Text(L10n.of(context).yesPleaseUpdate),
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
  void onTapLinkChildRoom(BuildContext context, String roomId) async {
    final selectedParentSpaceId = ref.read(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.read(spaceProvider(selectedParentSpaceId).future);
    space.addChildRoom(roomId);

    //Make subspace
    if (widget.childRoomType == ChildRoomType.space) {
      //Fetch selected room data and add given parentSpaceId as parent
      final room = await ref.read(maybeRoomProvider(roomId).future);
      if (room != null) {
        room.addParentRoom(selectedParentSpaceId, true);
        // ignore: use_build_context_synchronously
        await checkJoinRule(context, room, selectedParentSpaceId);
      }
    }

    if (widget.childRoomType == ChildRoomType.recommendedSpace) {
      recommendedChildSpaceIds.add(roomId);
    } else {
      childRoomsIds.add(roomId);
    }
    // spaceRelations come from the server and must be manually invalidated
    ref.invalidate(spaceRelationsOverviewProvider(selectedParentSpaceId));
  }

//Unlink child room
  void onTapUnlinkChildRoom(String roomId) async {
    final selectedParentSpaceId = ref.read(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.read(spaceProvider(selectedParentSpaceId).future);
    if (!mounted) return;
    space.removeChildRoom(roomId, L10n.of(context).unlinkRoom);

    if (widget.childRoomType == ChildRoomType.space) {
      //Fetch selected room data and add given parentSpaceId as parent
      final room = await ref.read(maybeRoomProvider(roomId).future);
      if (room != null && mounted) {
        room.removeParentRoom(
          selectedParentSpaceId,
          L10n.of(context).unlinkRoom,
        );
      }
    }

    if (widget.childRoomType == ChildRoomType.recommendedSpace) {
      recommendedChildSpaceIds.remove(roomId);
    } else {
      childRoomsIds.remove(roomId);
    }
    // spaceRelations come from the server and must be manually invalidated
    ref.invalidate(spaceRelationsOverviewProvider(selectedParentSpaceId));
  }
}
