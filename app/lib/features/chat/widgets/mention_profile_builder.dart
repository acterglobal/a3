import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MentionProfileBuilder extends ConsumerWidget {
  final String roomId;
  final String authorId;

  const MentionProfileBuilder({
    super.key,
    required this.roomId,
    required this.authorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionProfile =
        ref.watch(roomMemberProvider((userId: authorId, roomId: roomId)));
    return mentionProfile.when(
      data: (data) => ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: authorId,
          avatar: data.profile.getAvatarImage(),
          displayName: data.profile.displayName,
        ),
        size: 18,
      ),
      error: (e, st) {
        return ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(uniqueId: authorId),
          size: 18,
        );
      },
      loading: () => Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(uniqueId: authorId),
          size: 18,
        ),
      ),
    );
  }
}
