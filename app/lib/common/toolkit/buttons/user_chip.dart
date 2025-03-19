import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserChip extends ConsumerWidget {
  final String roomId;
  final String memberId;
  final TextStyle? style;
  final Widget? Function(
    BuildContext context, {
    required bool isMe,
    required double fontSize,
  })?
  trailingBuilder;
  final Function(
    BuildContext context, {
    required bool isMe,
    required VoidCallback defaultOnTap,
  })?
  onTap;

  const UserChip({
    super.key,
    required this.roomId,
    required this.memberId,
    this.style,
    this.trailingBuilder,
    this.onTap,
  });

  Future<void> onTapFallback(BuildContext context) async {
    await showMemberInfoDrawer(
      context: context,
      roomId: roomId,
      memberId: memberId,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: memberId)),
    );
    final isMe = memberId == ref.watch(myUserIdStrProvider);
    final style = this.style ?? Theme.of(context).textTheme.bodySmall;
    final fontSize = style?.fontSize ?? 12.0;
    final decoration =
        isMe
            ? BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(fontSize),
            )
            : BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(fontSize),
            );
    final trailing = trailingBuilder?.call(
      context,
      isMe: isMe,
      fontSize: fontSize,
    );
    final onTap =
        this.onTap ??
        (
          BuildContext context, {
          required bool isMe,
          required VoidCallback defaultOnTap,
        }) => onTapFallback(context);

    return Tooltip(
      message: memberId,
      child: InkWell(
        onTap:
            () => onTap(
              context,
              isMe: isMe,
              defaultOnTap: () => onTapFallback(context),
            ),
        child: Container(
          decoration: decoration,
          padding: EdgeInsets.symmetric(
            horizontal: (fontSize / 2).toDouble(),
            vertical: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActerAvatar(
                options: AvatarOptions.DM(memberInfo, size: fontSize / 2),
              ),
              SizedBox(width: 4),
              if (isMe)
                Text(
                  L10n.of(context).you,
                  style: style?.copyWith(fontWeight: FontWeight.bold),
                )
              else
                Text(memberInfo.displayName ?? memberId, style: style),
              if (trailing != null)
                Padding(padding: EdgeInsets.only(left: 4), child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}
