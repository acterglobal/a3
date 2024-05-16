import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomToInviteTo extends ConsumerWidget {
  final String roomId;
  final GestureTapCallback onRemove;

  const RoomToInviteTo({
    super.key,
    required this.roomId,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    String subtitle = L10n.of(context).unknownRoom;
    if (room != null) {
      if (room.isSpace()) {
        final space = ref.watch(spaceProvider(roomId)).valueOrNull;
        if (space != null) {
          return SpaceCard(
            space: space,
            showParent: true,
            trailing: removeWidget(),
          );
        }
        subtitle = L10n.of(context).loadingRoom;
      } else {
        final chat = ref.watch(chatProvider(roomId)).valueOrNull;
        if (chat != null) {
          return ConvoCard(
            room: chat,
            showParent: true,
            trailing: removeWidget(),
          );
        }
        subtitle = L10n.of(context).loadingChat;
      }
    }
    return Card(
      child: ListTile(
        title: Text(roomId),
        subtitle: Text(subtitle),
        trailing: removeWidget(),
      ),
    );
  }

  Widget removeWidget() {
    return InkWell(
      onTap: onRemove,
      child: Icon(
        Atlas.trash_can_thin,
        key: Key('room-to-invite-$roomId-remove'),
      ),
    );
  }
}
