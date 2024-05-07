import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/rooms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RoomHierarchyJoinButton extends ConsumerWidget {
  final Function(String) forward;
  final String roomId;
  final String joinRule;
  final String roomName;
  final String? viaServerName;

  const RoomHierarchyJoinButton({
    super.key,
    required this.joinRule,
    required this.roomId,
    required this.roomName,
    required this.viaServerName,
    required this.forward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maybeRoom = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    if (maybeRoom != null) {
      // we know that room already \o/
      return OutlinedButton(
        onPressed: () => forward(roomId),
        child: Text(L10n.of(context).joined),
      );
    }
    switch (joinRule) {
      case 'private':
      case 'invite':
        return Tooltip(
          message: L10n.of(context).youNeedBeInvitedToJoinThisRoom,
          child: Chip(label: Text(L10n.of(context).private)),
        );
      case 'restricted':
        return Tooltip(
          message: L10n.of(context).youAreAbleToJoinThisRoom,
          child: OutlinedButton(
            onPressed: () async {
              await joinRoom(
                context,
                ref,
                L10n.of(context).tryingToJoin(roomName),
                roomId,
                viaServerName,
                forward,
              );
            },
            child: Text(L10n.of(context).join),
          ),
        );
      case 'public':
        return Tooltip(
          message: L10n.of(context).youAreAbleToJoinThisRoom,
          child: OutlinedButton(
            onPressed: () async {
              await joinRoom(
                context,
                ref,
                L10n.of(context).tryingToJoin(roomName),
                roomId,
                viaServerName,
                forward,
              );
            },
            child: Text(L10n.of(context).join),
          ),
        );
      default:
        return Tooltip(
          message: L10n.of(context).unclearJoinRule(joinRule),
          child: Chip(label: Text(L10n.of(context).unknown)),
        );
    }
  }
}
