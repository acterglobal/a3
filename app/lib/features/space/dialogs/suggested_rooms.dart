import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/chat/convo_hierarchy_card.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/spaces/space_hierarchy_card.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter/features/space/actions/has_seen_suggested.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::spaces::suggested_rooms');

class _SuggestedRooms extends ConsumerStatefulWidget {
  final String spaceId;
  const _SuggestedRooms({
    required this.spaceId,
  });

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

    ref.listenManual(
      suggestedRoomsProvider(widget.spaceId),
      (prev, next) {
        if (next.hasValue) {
          setState(() {
            chatsFound = next.valueOrNull?.chats ?? [];
            spacesFound = next.valueOrNull?.spaces ?? [];
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultDialog(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.8,
      title: Text(
        L10n.of(context).suggestedRoomsTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        children: [
          Text(L10n.of(context).suggestedRoomsSubtitle),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (selectedRooms != [])
                ActerInlineTextButton(
                  onPressed: () {
                    setState(() {
                      selectedRooms = [];
                    });
                  },
                  child: Text(L10n.of(context).unselectAll),
                ),
              if (selectedRooms != null)
                ActerInlineTextButton(
                  onPressed: () {
                    setState(() {
                      selectedRooms = null;
                    });
                  },
                  child: Text(L10n.of(context).selectAll),
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
          child: Text(L10n.of(context).skip),
        ),
        if (selectedRooms != [])
          ActerPrimaryActionButton(
            onPressed: () => _joinSelected(context),
            child: Text(L10n.of(context).join),
          ),
      ],
    );
  }

  void _toggle(String roomId) {
    List<String> newSelectedRooms = selectedRooms ?? [];
    if (selectedRooms == null) {
      // we had been an _all_ selection, but now we need to take one out.
      newSelectedRooms =
          chatsFound.followedBy(spacesFound).map((e) => e.roomIdStr()).toList();
    }
    if (!newSelectedRooms.remove(roomId)) {
      // was not in, add it new
      newSelectedRooms.add(roomId);
    }
    setState(() {
      selectedRooms = newSelectedRooms;
    });
  }

  void _joinSelected(BuildContext context) async {
    final allRooms = chatsFound.followedBy(spacesFound).toList();
    List<SpaceHierarchyRoomInfo> roomsToJoin = [];
    bool hadFailures = false;

    if (selectedRooms == null) {
      roomsToJoin = allRooms;
    } else {
      final casted = allRooms.cast<SpaceHierarchyRoomInfo?>();
      for (final roomId in selectedRooms!) {
        final room = casted.firstWhere(
          (s) => s!.roomIdStr() == roomId,
          orElse: () => null,
        );
        if (room != null) {
          // it was found
          roomsToJoin.add(room);
        } else {
          _log.warning(
            'Room $roomId not found in list. Not sure how that can ever be.',
          );
        }
      }
    }
    final displayMsg = L10n.of(context).joiningSuggested;
    for (final room in roomsToJoin) {
      final roomId = room.roomIdStr();
      try {
        final server = room.viaServerName();
        final newRoomId =
            await joinRoom(context, ref, displayMsg, roomId, server, null);
        if (newRoomId == null) {
          _log.warning('Joining $roomId failed');
          hadFailures = true;
        }
      } catch (error, stack) {
        _log.severe('Joining $roomId failed', error, stack);
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
          return SpaceHierarchyCard(
            onTap: () => _toggle(roomId),
            roomInfo: item,
            parentId: widget.spaceId,
            contentPadding: EdgeInsets.zero,
            trailing: Switch(
              onChanged: (value) => _toggle(roomId),
              value: selectedRooms == null
                  ? true
                  : selectedRooms!.contains(roomId),
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
          return ConvoHierarchyCard(
            onTap: () => _toggle(roomId),
            parentId: widget.spaceId,
            roomInfo: item,
            contentPadding: EdgeInsets.zero,
            trailing: Switch(
              onChanged: (value) => _toggle(roomId),
              value: selectedRooms == null
                  ? true
                  : selectedRooms!.contains(roomId),
            ),
          );
        },
      ),
    ];
  }
}

void showSuggestRoomsDialog(
  BuildContext context,
  WidgetRef ref,
  String spaceId,
) {
  showAdaptiveDialog(
    barrierDismissible: true,
    context: context,
    useRootNavigator: true,
    builder: (context) => _SuggestedRooms(
      spaceId: spaceId,
    ),
  );
}
