import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomChip extends ConsumerWidget {
  final String roomId;

  const RoomChip({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ??
            L10n.of(context).unknown;
    final avatarSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    return Tooltip(
      message: roomId,
      child: ActerInlineTextButton.icon(
        icon: ActerAvatar(
          options: AvatarOptions(
            ref.watch(roomAvatarInfoProvider(roomId)),
            size: avatarSize,
          ),
        ),
        label: Text(displayName, overflow: TextOverflow.ellipsis),
        onPressed: () async {
          await navigateToRoomOrAskToJoin(context, ref, roomId);
        },
      ),
    );
  }
}
