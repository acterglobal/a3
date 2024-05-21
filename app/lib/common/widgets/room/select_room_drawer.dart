import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';

import 'package:acter/common/widgets/room/brief_room_list_entry.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

// ChildRoomType configures the sub child type of the `Spaces`
enum RoomType {
  groupChat,
  space,
}

class SelectRoomDrawer extends ConsumerStatefulWidget {
  final String canCheck;
  final String? currentSpaceId;
  final Widget title;
  final String keyPrefix;
  final RoomType roomType;

  const SelectRoomDrawer({
    super.key,
    required this.canCheck,
    this.currentSpaceId,
    required this.title,
    required this.roomType,
    required this.keyPrefix,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SelectRoomDrawerState();

  DisplayMode get avatarDisplayMode => switch (roomType) {
        RoomType.space => DisplayMode.Space,
        RoomType.groupChat => DisplayMode.GroupChat
      };
}

class _SelectRoomDrawerState extends ConsumerState<SelectRoomDrawer> {
  final TextEditingController searchTextController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ensure we are synced up
    searchTextController.text = ref.read(roomSearchValueProvider) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        key: widget.key,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          title(context),
          searchBar(context),
          Flexible(
            child: roomsList(context),
          ),
        ],
      ),
    );
  }

  Widget title(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: widget.title,
      actions: [
        TextButton.icon(
          icon: const Icon(Atlas.minus_circle_thin),
          onPressed: () {
            Navigator.pop(context, '');
          },
          label: Text(L10n.of(context).clear),
        ),
      ],
    );
  }

  Widget searchBar(BuildContext context) {
    if (allRooms().length < 10) {
      // small list, ignore
      return const SizedBox.shrink();
    }

    final hasSearchTerm = (ref.read(roomSearchValueProvider) ?? '').isNotEmpty;

    return SearchBar(
      controller: searchTextController,
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Atlas.magnifying_glass),
      ),
      hintText: L10n.of(context).search,
      trailing: hasSearchTerm
          ? [
              InkWell(
                onTap: () {
                  searchTextController.clear();
                  ref.read(roomSearchValueProvider.notifier).state = '';
                },
                child: const Icon(Icons.clear),
              ),
            ]
          : null,
      onChanged: (value) {
        ref.read(roomSearchValueProvider.notifier).state = value;
      },
    );
  }

  List<String> allRooms() {
    return switch (widget.roomType) {
      RoomType.space =>
        ref.watch(spacesProvider).map((space) => space.getRoomIdStr()).toList(),
      RoomType.groupChat => ref
          .watch(chatsProvider.select((v) => v.where((d) => !d.isDm())))
          .map((room) => room.getRoomIdStr())
          .toList(),
    };
  }

  Widget roomsList(BuildContext context) {
    final searchValue = ref.watch(roomSearchValueProvider);
    if (searchValue?.isNotEmpty == true) {
      return searchedRoomsList(context);
    }

    return roomsListUI(allRooms());
  }

//Show space list based on the search term
  Widget searchedRoomsList(BuildContext context) {
    final searchedrooms = ref.watch(
      switch (widget.roomType) {
        RoomType.space => searchedSpacesProvider,
        RoomType.groupChat => roomSearchedChatsProvider,
      },
    );

    return searchedrooms.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            heightFactor: 10,
            child: Text(L10n.of(context).noChatsFoundMatchingYourSearchTerm),
          );
        }
        return roomsListUI(rooms);
      },
      loading: () => const Center(
        heightFactor: 10,
        child: CircularProgressIndicator(),
      ),
      error: (e, s) => Center(child: Text(L10n.of(context).searchingFailed(e))),
    );
  }

  Widget roomsListUI(List<String> rooms) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final roomId = rooms[index];
        return BriefRoomEntry(
          roomId: roomId,
          avatarDisplayMode: widget.avatarDisplayMode,
          keyPrefix: widget.keyPrefix,
          selectedValue: current,
          canCheck: widget.canCheck,
          onSelect: (roomId) {
            Navigator.pop(context, roomId);
          },
        );
      },
    );
  }
}
