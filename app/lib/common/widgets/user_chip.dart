import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserChip extends ConsumerWidget {
  final VisualDensity? visualDensity;
  final String roomId;
  final String memberId;
  final Widget? deleteIcon;
  final VoidCallback? onDeleted;

  const UserChip({
    super.key,
    required this.roomId,
    required this.memberId,
    this.deleteIcon,
    this.onDeleted,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: memberId)),
    );
    return Chip(
      visualDensity: visualDensity,
      avatar: ActerAvatar(
        options: AvatarOptions.DM(
          memberInfo,
          size: 24,
        ),
      ),
      label: Text(memberInfo.displayName ?? memberId),
      onDeleted: onDeleted,
      deleteIcon: deleteIcon,
    );
  }
}
