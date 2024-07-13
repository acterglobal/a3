import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserChip extends ConsumerWidget {
  final String roomId;
  final String memberId;

  const UserChip({
    super.key,
    required this.roomId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: memberId)),
    );
    final avatarSize = Theme.of(context).textTheme.bodySmall?.fontSize ?? 12.0;
    return Tooltip(
      message: memberId,
      child: ActerInlineTextButton.icon(
        icon: ActerAvatar(
          options: AvatarOptions.DM(
            memberInfo,
            size: avatarSize,
          ),
        ),
        label: Text(memberInfo.displayName ?? memberId),
        onPressed: () async {
          await showMemberInfoDrawer(
            context: context,
            roomId: roomId,
            memberId: memberId,
            // isShowActions: false,
          );
        },
      ),
    );
  }
}
