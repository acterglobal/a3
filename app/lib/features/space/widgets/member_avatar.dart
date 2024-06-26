import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::member_avatar');

class MemberAvatar extends ConsumerWidget {
  final String roomId;
  final String memberId;

  const MemberAvatar({super.key, required this.memberId, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo =
        ref.watch(roomMemberProvider((userId: memberId, roomId: roomId)));
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: avatarInfo.when(
        data: (data) => ActerAvatar(
          options: AvatarOptions.DM(
            AvatarInfo(
              uniqueId: memberId,
              avatar: data.avatarInfo.avatar,
              displayName: data.avatarInfo.displayName,
            ),
            size: 18,
          ),
        ),
        error: (err, stackTrace) {
          _log.severe("Couldn't load avatar", err, stackTrace);
          return ActerAvatar(
            options: AvatarOptions.DM(
              AvatarInfo(
                uniqueId: memberId,
                displayName: memberId,
              ),
              size: 18,
            ),
          );
        },
        loading: () => Skeletonizer(
          child: ActerAvatar(
            options: AvatarOptions.DM(
              AvatarInfo(uniqueId: memberId),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
