import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/room/brief_room_list_entry.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

final _log = Logger('a3::common::room::select_drawer');

// ChildRoomType configures the sub child type of the `Spaces`
enum RoomType { groupChat, space }

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

  DisplayMode get avatarDisplayMode {
    return switch (roomType) {
      RoomType.space => DisplayMode.Space,
      RoomType.groupChat => DisplayMode.GroupChat,
    };
  }
}

class _SelectRoomDrawerState extends ConsumerState<SelectRoomDrawer> {
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
          ActerSearchWidget(
            padding: EdgeInsets.zero,
            onChanged: (String value) {
              ref.read(roomSearchValueProvider.notifier).state = value;
            },
            onClear: () {
              ref.read(roomSearchValueProvider.notifier).state = '';
            },
          ),
          Flexible(child: roomsList(context)),
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

  List<String> allRooms() {
    return switch (widget.roomType) {
      RoomType.space =>
        ref
            .watch(bookmarkedSpacesProvider)
            .followedBy(ref.watch(unbookmarkedSpacesProvider))
            .map((space) => space.getRoomIdStr())
            .toList(),
      RoomType.groupChat =>
        ref
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
    final roomsLoader = switch (widget.roomType) {
      RoomType.space => ref.watch(searchedSpacesProvider),
      RoomType.groupChat => ref.watch(roomSearchedChatsProvider),
    };
    final lang = L10n.of(context);
    return roomsLoader.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            heightFactor: 10,
            child: Text(lang.noChatsFoundMatchingYourSearchTerm),
          );
        }
        return roomsListUI(rooms);
      },
      loading:
          () => const Center(
            heightFactor: 10,
            child: CircularProgressIndicator(),
          ),
      error: (e, s) {
        _log.severe('Failed to search space or convo', e, s);
        return Center(child: Text(lang.searchingFailed(e)));
      },
    );
  }

  Widget roomsListUI(List<String> rooms) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: rooms.length,
      itemBuilder:
          (context, index) => BriefRoomEntry(
            roomId: rooms[index],
            keyPrefix: widget.keyPrefix,
            selectedValue: current,
            canCheck: widget.canCheck,
            onSelect: (roomId) {
              Navigator.pop(context, roomId);
            },
          ),
    );
  }
}
