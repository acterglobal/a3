import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_button.dart';
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
    final selectedParentSpaceId = ref.watch(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;
    final space = await ref
        .watch(spaceRelationsOverviewProvider(selectedParentSpaceId).future);

    childRoomsIds.clear();
    if (widget.childRoomType == ChildRoomType.chat) {
      for (int i = 0; i < space.knownChats.length; i++) {
        childRoomsIds.add(space.knownChats[i].getRoomId().toString());
      }
    } else {
      for (int i = 0; i < space.knownSubspaces.length; i++) {
        childRoomsIds.add(space.knownSubspaces[i].getRoomId().toString());
      }
      //Add recommended child spaces ids
      recommendedChildSpaceIds.clear();
      for (int i = 0; i < space.otherRelations.length; i++) {
        recommendedChildSpaceIds
            .add(space.otherRelations[i].getRoomId().toString());
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
    if (searchValue != null && searchValue.isNotEmpty) {
      return searchedChatsList();
    }

    final chatList =
        ref.watch(chatsProvider).where((element) => (!element.isDm())).toList();
    return chatListUI(chatList);
  }

//Show chat list based on the search term
  Widget searchedChatsList() {
    return ref.watch(searchedChatsProvider).when(
          data: (chats) {
            var chatList = chats.where((element) => (!element.isDm())).toList();
            if (chatList.isEmpty) {
              return const Center(
                heightFactor: 10,
                child: Text('No chats found matching your search term'),
              );
            }
            return chatListUI(chatList);
          },
          loading: () => loadingUI(),
          error: (e, s) => errorUI('Searching failed', e),
        );
  }

//Chat List
  Widget chatListUI(List<Convo> chatList) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chatList.length,
      itemBuilder: (context, index) {
        final item = chatList[index];
        final roomItem =
            ref.watch(briefRoomItemWithMembershipProvider(item.getRoomIdStr()));
        return roomItem.when(
          data: (room) {
            final membership = room.membership;

            return roomListItemUI(
              roomId: room.roomId,
              displayName: room.roomProfileData.displayName,
              roomAvatar: room.roomProfileData.getAvatarImage(),
              displayMode: DisplayMode.Space,
              canLink: membership == null
                  ? false
                  : membership.canString('CanLinkSpaces'),
              isLinked: childRoomsIds.contains(room.roomId),
            );
          },
          skipLoadingOnReload: false,
          error: (e, s) => errorUI('Loading room failed ', e),
          loading: () => loadingUI(),
        );
      },
    );
  }

//List of spaces that can be linked according to the selected parent space
  Widget spacesList() {
    final searchValue = ref.watch(spaceSearchValueProvider);
    if (searchValue != null && searchValue.isNotEmpty) {
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
    return ref.watch(searchedSpacesProvider).when(
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
            enabled: canLink,
            leading: ActerAvatar(
              mode: displayMode,
              displayName: displayName,
              uniqueId: roomId,
              avatar: roomAvatar,
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
                  ? DefaultButton(
                      onPressed: () => onTapUnlinkChildRoom(roomId),
                      title: 'Unlink',
                      isOutlined: true,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )
                  : canLink
                      ? DefaultButton(
                          onPressed: () => onTapLinkChildRoom(roomId),
                          title: 'Link',
                          isOutlined: true,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.success,
                            ),
                          ),
                        )
                      : null,
            ),
          );
  }

//Link child room
  void onTapLinkChildRoom(String roomId) async {
    final selectedParentSpaceId = ref.watch(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.watch(spaceProvider(selectedParentSpaceId).future);
    space.addChildRoom(roomId);

    //Make subspace
    if (widget.childRoomType == ChildRoomType.space) {
      //Fetch selected room data and add given parentSpaceId as parent
      final room = await ref.watch(maybeRoomProvider(roomId).future);
      if (room != null) {
        room.addParentRoom(selectedParentSpaceId, true);
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
    final selectedParentSpaceId = ref.watch(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.watch(spaceProvider(selectedParentSpaceId).future);
    space.removeChildRoom(roomId, 'Unlink room');

    if (widget.childRoomType == ChildRoomType.space) {
      //Fetch selected room data and add given parentSpaceId as parent
      final room = await ref.watch(maybeRoomProvider(roomId).future);
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
