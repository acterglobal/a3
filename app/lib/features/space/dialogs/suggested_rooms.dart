import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/room/room_hierarchy_card.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter/features/space/actions/has_seen_suggested.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::suggested_rooms');

class _SuggestedRooms extends ConsumerStatefulWidget {
  final String spaceId;

  const _SuggestedRooms({required this.spaceId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __SuggestedRoomsState();
}

class __SuggestedRoomsState extends ConsumerState<_SuggestedRooms> {
  List<String>? selectedRooms;
  List<SpaceHierarchyRoomInfo> chatsFound = [];
  List<SpaceHierarchyRoomInfo> spacesFound = [];

  @override
  void initState() {
    super.initState();

    ref.listenManual(roomsToSuggestProvider(widget.spaceId), (prev, next) {
      if (next.hasValue) {
        setState(() {
          chatsFound = next.valueOrNull?.chats ?? [];
          spacesFound = next.valueOrNull?.spaces ?? [];
        });
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final screenSize = MediaQuery.of(context).size;
    return DefaultDialog(
      width: screenSize.width * 0.8,
      height: screenSize.height * 0.8,
      title: Text(
        lang.suggestedRoomsTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        children: [
          Text(lang.suggestedRoomsSubtitle),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (selectedRooms != [])
                ActerInlineTextButton(
                  onPressed: () {
                    setState(() => selectedRooms = []);
                  },
                  child: Text(lang.unselectAll),
                ),
              if (selectedRooms != null)
                ActerInlineTextButton(
                  onPressed: () {
                    setState(() => selectedRooms = null);
                  },
                  child: Text(lang.selectAll),
                ),
            ],
          ),
        ],
      ),
      description: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spacesFound.isNotEmpty) ..._renderSpacesSection(context),
          if (chatsFound.isNotEmpty) ..._renderChatsSection(context),
        ],
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () {
            markHasSeenSuggested(ref, widget.spaceId);
            Navigator.pop(context);
          },
          child: Text(lang.skip),
        ),
        if (selectedRooms != [])
          ActerPrimaryActionButton(
            onPressed: () => _joinSelected(context),
            child: Text(lang.join),
          ),
      ],
    );
  }

  void _toggle(String roomId) {
    List<String> newSelectedRooms =
        selectedRooms.map((rooms) => List.from(rooms)) ??
        // we had been an _all_ selection, but now we need to take one out.
        chatsFound.followedBy(spacesFound).map((e) => e.roomIdStr()).toList();
    if (!newSelectedRooms.remove(roomId)) {
      // was not in, add it new
      newSelectedRooms.add(roomId);
    }
    setState(() => selectedRooms = newSelectedRooms);
  }

  Future<void> _joinSelected(BuildContext context) async {
    final allRooms = chatsFound.followedBy(spacesFound).toList();
    List<SpaceHierarchyRoomInfo> roomsToJoin =
        selectedRooms.map(
          (p0) =>
              p0
                  .where((rId) {
                    final found = allRooms.any((r) => r.roomIdStr() == rId);
                    if (!found) {
                      _log.warning(
                        'Room $rId not found in list. Not sure how that can ever be.',
                      );
                    }
                    return found;
                  })
                  .map(
                    (rId) => allRooms.firstWhere((r) => r.roomIdStr() == rId),
                  )
                  .toList(),
        ) ??
        allRooms;
    bool hadFailures = false;

    final displayMsg = L10n.of(context).joiningSuggested;
    for (final room in roomsToJoin) {
      final roomId = room.roomIdStr();
      try {
        final servers = room.viaServerNames().toDart();
        final newRoomId = await joinRoom(
          lang: L10n.of(context),
          ref: ref,
          roomIdOrAlias: roomId,
          serverNames: servers,
          displayMsg: displayMsg,
        );
        if (newRoomId == null) {
          _log.warning('Joining $roomId failed');
          hadFailures = true;
        }
      } catch (e, s) {
        _log.severe('Joining $roomId failed', e, s);
        hadFailures = true;
      }
    }

    if (!hadFailures) {
      markHasSeenSuggested(ref, widget.spaceId);
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  List<Widget> _renderSpacesSection(BuildContext context) {
    return [
      Text(
        L10n.of(context).spaces,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      ListView.builder(
        shrinkWrap: true,
        itemCount: spacesFound.length,
        itemBuilder: (context, idx) {
          final item = spacesFound[idx];
          final roomId = item.roomIdStr();
          return RoomHierarchyCard(
            onTap: () => _toggle(roomId),
            roomInfo: item,
            parentId: widget.spaceId,
            contentPadding: EdgeInsets.zero,
            trailing: Switch(
              onChanged: (value) => _toggle(roomId),
              value:
                  selectedRooms.map((rooms) => rooms.contains(roomId)) ?? true,
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _renderChatsSection(BuildContext context) {
    return [
      Text(
        L10n.of(context).chats,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      ListView.builder(
        shrinkWrap: true,
        itemCount: chatsFound.length,
        itemBuilder: (context, idx) {
          final item = chatsFound[idx];
          final roomId = item.roomIdStr();
          return RoomHierarchyCard(
            onTap: () => _toggle(roomId),
            parentId: widget.spaceId,
            roomInfo: item,
            contentPadding: EdgeInsets.zero,
            trailing: Switch(
              onChanged: (value) => _toggle(roomId),
              value:
                  selectedRooms.map((rooms) => rooms.contains(roomId)) ?? true,
            ),
          );
        },
      ),
    ];
  }
}

Future<void> showSuggestRoomsDialog(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
) async {
  await showAdaptiveDialog(
    barrierDismissible: true,
    context: context,
    useRootNavigator: false,
    builder: (context) => _SuggestedRooms(spaceId: spaceId),
  );
}
