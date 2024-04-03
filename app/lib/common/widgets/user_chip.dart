import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    final memberInfo =
        ref.watch(roomMemberProvider((roomId: roomId, userId: memberId)));
    return memberInfo.when(
      data: (data) => Chip(
        visualDensity: visualDensity,
        avatar: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: memberId,
            displayName: data.profile.displayName,
            avatar: data.profile.getAvatarImage(),
          ),
          size: 24,
        ),
        label: Text(data.profile.displayName ?? memberId),
        onDeleted: onDeleted,
        deleteIcon: deleteIcon,
      ),
      error: (e, s) => Chip(
        label: Text(L10n.of(context).errorLoadingMember(memberId, e)),
      ),
      loading: () => Skeletonizer(
        child: Chip(
          visualDensity: visualDensity,
          avatar: const Icon(Atlas.user_thin),
          label: Text(memberId),
          onDeleted: onDeleted,
          deleteIcon: deleteIcon,
        ),
      ),
    );
  }
}
