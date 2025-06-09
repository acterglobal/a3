import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/widgets/acter_inline_chip.dart';
import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserChip extends ConsumerWidget {
  final String? roomId;
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
    this.roomId,
    required this.memberId,
    this.style,
    this.trailingBuilder,
    this.onTap,
  });

  Future<void> onTapFallback(BuildContext context) async {
    final rId = roomId;
    if (rId == null) {
      // add support for non-member users
      return;
    }
    await showMemberInfoDrawer(
      context: context,
      roomId: rId,
      memberId: memberId,
    );
  }

  AvatarInfo getMemberInfo(WidgetRef ref) {
    final rId = roomId;
    if (rId == null) {
      // add support for non-member users
      return AvatarInfo(uniqueId: memberId, displayName: null, avatar: null);
    }
    return ref.watch(memberAvatarInfoProvider((roomId: rId, userId: memberId)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberInfo = getMemberInfo(ref);
    final isMe = memberId == ref.watch(myUserIdStrProvider);
    final style = this.style ?? Theme.of(context).textTheme.bodySmall;
    final fontSize = style?.fontSize ?? 12.0;
    final decoration =
        isMe
            ? BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            )
            : BoxDecoration(
              color: Colors.black12,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
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

    return ActerInlineChip(
      style: style,
      tooltip: memberId,
      leading: ActerAvatar(
        options: AvatarOptions.DM(memberInfo, size: fontSize / 1.75),
      ),
      trailing: trailing,
      textStyle: isMe ? style?.copyWith(fontWeight: FontWeight.bold) : style,
      decoration: decoration,
      text: isMe ? L10n.of(context).you : memberInfo.displayName ?? memberId,
      onTap:
          () => onTap(
            context,
            isMe: isMe,
            defaultOnTap: () => onTapFallback(context),
          ),
    );
  }
}
