import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AvatarBuilder extends ConsumerWidget {
  final String roomId;
  final String userId;

  const AvatarBuilder({super.key, required this.userId, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((userId: userId, roomId: roomId)),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActerAvatar(
        options: AvatarOptions.DM(
          AvatarInfo(
            uniqueId: userId,
            displayName: avatarInfo.displayName ?? userId,
            avatar: avatarInfo.avatar,
            onAvatarTap: () async {
              // ignore: use_build_context_synchronously
              showMemberInfoDrawer(
                context: context,
                roomId: roomId,
                memberId: userId,
              );
            },
          ),
          size: 14,
        ),
      ),
    );
  }
}
