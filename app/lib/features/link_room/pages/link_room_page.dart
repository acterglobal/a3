import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/search.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/link_room/types.dart';
import 'package:acter/features/link_room/widgets/link_space_list_item.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::link_room_sheet');

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
              child:
                  widget.childRoomType == ChildRoomType.chat
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
      child:
          space.map(
            (p0) => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context).parentSpace),
                SpaceChip(spaceId: p0.roomId, onTapOpenSpaceDetail: false),
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
        (rooms) =>
            rooms
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
      data:
          (chats) =>
              chats.isEmpty
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
      itemBuilder:
          (context, index) => LinkRoomListItem(
            parentId: widget.parentSpaceId,
            roomId: chatList[index],
          ),
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
      itemBuilder:
          (context, index) => LinkRoomListItem(
            parentId: widget.parentSpaceId,
            roomId: spacesList[index],
          ),
    );
  }

  //Common loading UI
  Widget loadingUI() {
    return const Center(heightFactor: 10, child: CircularProgressIndicator());
  }

  //Common error UI
  Widget errorUI(String message) {
    return Center(child: Text(message));
  }
}
