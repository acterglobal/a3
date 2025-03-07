import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberAvatar extends ConsumerWidget {
  final String roomId;
  final String memberId;

  const MemberAvatar({super.key, required this.memberId, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((userId: memberId, roomId: roomId)),
    );
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 14)),
    );
  }
}
