import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberListEntry extends ConsumerWidget {
  final String memberId;
  final String roomId;
  final Member? myMembership;
  final bool isShowActions;

  const MemberListEntry({
    super.key,
    required this.memberId,
    required this.roomId,
    this.myMembership,
    this.isShowActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final memberStatus =
        ref
            .watch(membershipStatusStr((roomId: roomId, userId: memberId)))
            .valueOrNull;
    Widget? trailing;
    if (memberStatus == 'Admin') {
      trailing = const Tooltip(
        message: 'Admin',
        child: Icon(Atlas.crown_winner_thin),
      );
    } else if (memberStatus == 'Mod') {
      trailing = const Tooltip(
        message: 'Moderator',
        child: Icon(Atlas.shield_star_win_thin),
      );
    }

    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((userId: memberId, roomId: roomId)),
    );

    return ListTile(
      onTap: () async {
        if (context.mounted) {
          await showMemberInfoDrawer(
            context: context,
            roomId: roomId,
            memberId: memberId,
            isShowActions: isShowActions,
          );
        }
      },
      leading: ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 18)),
      title: Text(
        avatarInfo.displayName ?? memberId,
        style: textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          avatarInfo.displayName != null
              ? Text(
                memberId,
                style: textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              )
              : null,
      trailing: trailing,
    );
  }
}
