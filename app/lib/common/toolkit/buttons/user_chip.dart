import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';

class UserChip extends ConsumerWidget {
  final String roomId;
  final String memberId;
  final TextStyle? style;

  const UserChip({
    super.key,
    required this.roomId,
    required this.memberId,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: memberId)),
    );
    final isMe = memberId == ref.watch(myUserIdStrProvider);
    final style = this.style ?? Theme.of(context).textTheme.bodySmall;
    final fontSize = style?.fontSize ?? 12.0;
    return Tooltip(
      message: memberId,
      child: InkWell(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActerAvatar(
              options: AvatarOptions.DM(memberInfo, size: fontSize / 2),
            ),
            SizedBox(width: 4),
            if (isMe)
              Text(
                memberInfo.displayName ?? memberId,
                style: style?.copyWith(fontStyle: FontStyle.italic),
              )
            else
              Text(memberInfo.displayName ?? memberId, style: style),
          ],
        ),
        onTap: () async {
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
