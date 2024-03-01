import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/search.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return SideSheet(
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
        if (widget.childRoomType == ChildRoomType.chat) {
          ref.read(chatSearchValueProvider.notifier).update((state) => value);
        } else if (widget.childRoomType == ChildRoomType.space) {
          ref.read(spaceSearchValueProvider.notifier).update((state) => value);
        }
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
                    const Text('Parent Space'),
                    SpaceChip(space: space),
                  ],
                );
        },
        error: (e, s) => errorUI('error: ', e),
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
    final searchValue = ref.watch(chatSearchValueProvider);
    if (searchValue?.isNotEmpty == true) {
      return searchedChatsList();
    }

    final chatList = ref.watch(briefRoomItemsWithMembershipProvider);
    return chatList.when(
      data: (chats) =>
          chats.isEmpty ? const Text('no chats found') : chatListUI(chats),
      error: (e, s) => errorUI('Error loading chats', e),
      loading: () => loadingUI(),
    );
  }

//Show chat list based on the search term
  Widget searchedChatsList() {
    final searchedList = ref.watch(roomSearchedChatsProvider);
    return searchedList.when(
      data: (chats) => chats.isEmpty
          ? const Text('No chats found matching your search term')
          : chatListUI(chats),
      error: (e, s) => errorUI('Searching failed', e),
      loading: () => loadingUI(),
    );
  }

//Chat List
  Widget chatListUI(List<RoomItem> chatList) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chatList.length,
      itemBuilder: (context, index) {
        final room = chatList[index];
        return roomListItemUI(
          roomId: room.roomId,
          displayName: room.roomProfileData.displayName,
          roomAvatar: room.roomProfileData.getAvatarImage(),
          displayMode: DisplayMode.Space,
          canLink: room.membership == null
              ? false
              : room.membership!.canString('CanLinkSpaces'),
          isLinked: childRoomsIds.contains(room.roomId),
        );
      },
    );
  }

//List of spaces that can be linked according to the selected parent space
  Widget spacesList() {
    final searchValue = ref.watch(spaceSearchValueProvider);
    if (searchValue?.isNotEmpty == true) {
      return searchedSpaceList();
    }

    final spacesList = ref.watch(briefSpaceItemsProviderWithMembership);
    return spacesList.when(
      data: (spaces) =>
          spaces.isEmpty ? const Text('no spaces found') : spaceListUI(spaces),
      error: (e, s) => errorUI('Error loading spaces', e),
      loading: () => loadingUI(),
    );
  }

//Show space list based on the search term
  Widget searchedSpaceList() {
    final searchedSpaces = ref.watch(searchedSpacesProvider);
    return searchedSpaces.when(
      data: (spaces) {
        if (spaces.isEmpty) {
          return const Center(
            heightFactor: 10,
            child: Text('No chats found matching your search term'),
          );
        }
        return spaceListUI(spaces);
      },
      loading: () => loadingUI(),
      error: (e, s) => errorUI('Searching failed', e),
    );
  }

//Space List
  Widget spaceListUI(List<SpaceItem> spacesList) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: spacesList.length,
      itemBuilder: (context, index) {
        final item = spacesList[index];
        final membership = item.membership;
        final isSubspace = childRoomsIds.contains(item.roomId);
        final isLinked = widget.childRoomType == ChildRoomType.space
            ? childRoomsIds.contains(item.roomId)
            : recommendedChildSpaceIds.contains(item.roomId);
        final canLink =
            membership == null ? false : membership.canString('CanLinkSpaces');

        return roomListItemUI(
          roomId: item.roomId,
          displayName: item.spaceProfileData.displayName,
          roomAvatar: item.spaceProfileData.getAvatarImage(),
          displayMode: DisplayMode.Space,
          canLink: widget.childRoomType == ChildRoomType.recommendedSpace
              ? !isSubspace
              : canLink,
          isLinked: isLinked,
          isSubspace: isSubspace,
          isRecommendedSpace: recommendedChildSpaceIds.contains(item.roomId),
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
  Widget errorUI(String message, e) {
    return Center(
      child: Text('$message : $e'),
    );
  }

//Room list item UI
  Widget roomListItemUI({
    required String roomId,
    required String? displayName,
    required MemoryImage? roomAvatar,
    required DisplayMode displayMode,
    required bool canLink,
    required bool isLinked,
    bool isSubspace = false,
    bool isRecommendedSpace = false,
  }) {
    return widget.parentSpaceId == roomId
        ? const SizedBox.shrink()
        : ListTile(
            key: Key('room-list-item-$roomId'),
            enabled: canLink,
            leading: ActerAvatar(
              mode: displayMode,
              avatarInfo: AvatarInfo(
                uniqueId: roomId,
                displayName: displayName,
                avatar: roomAvatar,
              ),
              size: 24,
            ),
            title: Text(displayName ?? roomId),
            subtitle: isSubspace
                ? const Text('Subspace')
                : isRecommendedSpace
                    ? const Text('Recommended space')
                    : null,
            trailing: SizedBox(
              width: 100,
              child: isLinked
                  ? OutlinedButton(
                      onPressed: () => onTapUnlinkChildRoom(roomId),
                      key: Key('room-list-unlink-$roomId'),
                      child: const Text('Unlink'),
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
                          child: const Text('Link'),
                        )
                      : null,
            ),
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
      final parentSpaceName =
          spaceProfile.profile.displayName ?? 'the parent space';
      final roomProfile =
          await ref.read(roomProfileDataProvider(room.roomIdStr()).future);
      final roomName = roomProfile.displayName ?? 'the selected rooms';
      // ignore: use_build_context_synchronously
      bool shouldChange = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Not visible'),
            content: Wrap(
              children: [
                Text(
                  "The current join rules of $roomName mean it won't be visible for $parentSpaceName's members. Should we update the join rules to allow for $parentSpaceName's space member to see and join the $roomName?",
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                key: LinkRoomPage.denyJoinRuleUpdateKey,
                child: const Text('No, thanks'),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              TextButton(
                key: LinkRoomPage.confirmJoinRuleUpdateKey,
                child: const Text('Yes, please update'),
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
  }

//Unlink child room
  void onTapUnlinkChildRoom(String roomId) async {
    final selectedParentSpaceId = ref.read(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.read(spaceProvider(selectedParentSpaceId).future);
    space.removeChildRoom(roomId, 'Unlink room');

    if (widget.childRoomType == ChildRoomType.space) {
      //Fetch selected room data and add given parentSpaceId as parent
      final room = await ref.read(maybeRoomProvider(roomId).future);
      if (room != null) {
        room.removeParentRoom(selectedParentSpaceId, 'Unlink room');
      }
    }

    if (widget.childRoomType == ChildRoomType.recommendedSpace) {
      recommendedChildSpaceIds.remove(roomId);
    } else {
      childRoomsIds.remove(roomId);
    }
  }
}
