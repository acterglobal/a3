import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/widgets/room/brief_room_list_entry.dart';
import 'package:acter/common/widgets/search.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/space/actions/unlink_child_room.dart';
import 'package:acter/features/spaces/providers/space_list_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
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
  recommendedSpace,
}

class LinkRoomPage extends ConsumerStatefulWidget {
  static const confirmJoinRuleUpdateKey = Key('link-room-confirm-join-rule');
  static const denyJoinRuleUpdateKey = Key('link-room-deny-join-rule');

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
  Future<void> fetchKnownSubChatsData() async {
    final selectedParentSpaceId = ref.read(selectedSpaceIdProvider);
    if (selectedParentSpaceId == null) return;
    final space = await ref
        .read(spaceRelationsOverviewProvider(selectedParentSpaceId).future);

    childRoomsIds.clear();
    recommendedChildSpaceIds.clear();
    if (widget.childRoomType == ChildRoomType.chat) {
      childRoomsIds.addAll(space.knownChats);
    } else {
      childRoomsIds.addAll(space.knownSubspaces);
      recommendedChildSpaceIds
          .addAll(space.otherRelations.map((other) => other.getRoomIdStr()));
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
      child: space.let(
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
          keyPrefix: 'chat-list-link',
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
      itemBuilder: (context, index) {
        final lang = L10n.of(context);
        final roomId = spacesList[index];
        final isSubspace = childRoomsIds.contains(roomId);
        final isLinked = widget.childRoomType == ChildRoomType.space
            ? childRoomsIds.contains(roomId)
            : recommendedChildSpaceIds.contains(roomId);

        final subtitle = isSubspace
            ? Text(lang.subspace)
            : recommendedChildSpaceIds.contains(roomId)
                ? Text(lang.recommendedSpace)
                : null;

        return BriefRoomEntry(
          avatarDisplayMode: DisplayMode.Space,
          roomId: roomId,
          canCheck: 'CanLinkSpaces',
          keyPrefix: 'space-list-link',
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
    final lang = L10n.of(context);
    return SizedBox(
      width: 100,
      child: isLinked
          ? OutlinedButton(
              onPressed: () => onTapUnlinkChildRoom(roomId),
              key: Key('room-list-unlink-$roomId'),
              child: Text(lang.unlink),
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
                  child: Text(lang.link),
                )
              : null,
    );
  }

  Future<void> checkJoinRule(
    BuildContext context,
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
        //FIXME : Below is not working at all.
        await room.setJoinRule(update);
      }
    }
  }

//Link child room
  Future<void> onTapLinkChildRoom(BuildContext context, String roomId) async {
    final spaceId = ref.read(selectedSpaceIdProvider);
    if (spaceId == null) return;

    //Fetch selected parent space data and add given roomId as child
    final space = await ref.read(spaceProvider(spaceId).future);
    await space.addChildRoom(roomId, false);

    //Make subspace
    if (widget.childRoomType == ChildRoomType.space) {
      //Fetch selected room data and add given parentSpaceId as parent
      final room = await ref.read(maybeRoomProvider(roomId).future);
      if (room != null) {
        await room.addParentRoom(spaceId, true);
        if (!context.mounted) return;
        await checkJoinRule(context, room, spaceId);
      }
    }

    if (widget.childRoomType == ChildRoomType.recommendedSpace) {
      recommendedChildSpaceIds.add(roomId);
    } else {
      childRoomsIds.add(roomId);
    }

    invalidateProviders(spaceId);
  }

//Unlink child room
  Future<void> onTapUnlinkChildRoom(String roomId) async {
    final spaceId = ref.read(selectedSpaceIdProvider);
    if (spaceId == null) return;

    await unlinkChildRoom(
      context,
      ref,
      parentId: spaceId,
      roomId: roomId,
    );

    if (widget.childRoomType == ChildRoomType.recommendedSpace) {
      recommendedChildSpaceIds.remove(roomId);
    } else {
      childRoomsIds.remove(roomId);
    }

    //Invalidate providers
    invalidateProviders(spaceId);
  }

  void invalidateProviders(String selectedParentSpaceId) {
    //Invalidate providers
    ref.invalidate(spaceRelationsProvider(selectedParentSpaceId));
    ref.invalidate(spaceRemoteRelationsProvider(selectedParentSpaceId));
    ref.invalidate(subChatsListProvider(selectedParentSpaceId));
    ref.invalidate(subSpacesListProvider(selectedParentSpaceId));
    ref.invalidate(localCategoryListProvider);
  }
}
