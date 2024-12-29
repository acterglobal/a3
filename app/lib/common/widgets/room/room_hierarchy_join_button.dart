import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final lang = L10n.of(context);
    final maybeRoom = ref.watch(maybeRoomProvider(roomId));
    if (maybeRoom != null && maybeRoom.isJoined()) {
      // we know that room already \o/
      return OutlinedButton(
        onPressed: () => forward(roomId),
        child: Text(lang.joined),
      );
    }
    return switch (joinRule) {
      'private' || 'invite' => Tooltip(
          message: lang.youNeedBeInvitedToJoinThisRoom,
          child: Chip(
            label: Text(lang.private),
          ),
        ),
      'restricted' => Tooltip(
          message: lang.youAreAbleToJoinThisRoom,
          child: OutlinedButton(
            onPressed: () async {
              await joinRoom(
                context,
                ref,
                lang.tryingToJoin(roomName),
                roomId,
                viaServerName,
                forward,
              );
            },
            child: Text(lang.join),
          ),
        ),
      'public' => Tooltip(
          message: lang.youAreAbleToJoinThisRoom,
          child: OutlinedButton(
            onPressed: () async {
              await joinRoom(
                context,
                ref,
                lang.tryingToJoin(roomName),
                roomId,
                viaServerName,
                forward,
              );
            },
            child: Text(lang.join),
          ),
        ),
      _ => Tooltip(
          message: lang.unclearJoinRule(joinRule),
          child: Chip(
            label: Text(lang.unknown),
          ),
        ),
    };
  }
}
