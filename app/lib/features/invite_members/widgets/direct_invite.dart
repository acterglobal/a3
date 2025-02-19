import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/member/widgets/user_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DirectInvite extends ConsumerWidget {
  final String userId;
  final String roomId;

  const DirectInvite({
    super.key,
    required this.userId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invited =
        ref.watch(roomInvitedMembersProvider(roomId)).valueOrNull ?? [];
    final joined = ref.watch(membersIdsProvider(roomId)).valueOrNull ?? [];
    final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;

    return Card(
      child: ListTile(
        title: !isInvited(userId, invited) && !isJoined(userId, joined)
            ? Text(L10n.of(context).directInviteUser(userId))
            : Text(userId),
        trailing: room != null
            ? UserStateButton(
                userId: userId,
                room: room,
              )
            : const Skeletonizer(
                child: Text('Loading room'),
              ),
      ),
    );
  }
}
