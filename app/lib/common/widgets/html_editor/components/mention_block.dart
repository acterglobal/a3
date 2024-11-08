import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/html_editor/models/mention_block_keys.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MentionBlock extends ConsumerWidget {
  const MentionBlock({
    super.key,
    required this.node,
    required this.index,
    required this.mention,
    required this.userRoomId,
  });

  final Map<String, dynamic> mention;
  final String userRoomId;
  final Node node;
  final int index;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String type = mention[MentionBlockKeys.type];
    final String displayName = mention[MentionBlockKeys.displayName];
    final String mentionId = type == 'user'
        ? mention[MentionBlockKeys.userId]
        : mention[MentionBlockKeys.roomId];
    final avatarInfo = type == 'user'
        ? ref.watch(
            memberAvatarInfoProvider((roomId: userRoomId, userId: mentionId)),
          )
        : ref.watch(roomAvatarInfoProvider(mentionId));
    final options = type == 'user'
        ? AvatarOptions.DM(avatarInfo, size: 8)
        : AvatarOptions(avatarInfo, size: 16);

    return _mentionContent(
      context: context,
      mentionId: mentionId,
      displayName: displayName,
      avatarOptions: options,
      ref: ref,
    );
  }

  Widget _mentionContent({
    required BuildContext context,
    required String mentionId,
    required String displayName,
    required WidgetRef ref,
    required AvatarOptions avatarOptions,
  }) {
    final desktopPlatforms = [
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ];
    final name = displayName.isNotEmpty ? displayName : mentionId;
    final mentionContentWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).unselectedWidgetColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActerAvatar(options: avatarOptions),
          const SizedBox(width: 4),
          Text(name, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );

    final Widget content = GestureDetector(
      onTap: _handleUserTap,
      behavior: HitTestBehavior.opaque,
      child: desktopPlatforms.contains(Theme.of(context).platform)
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: mentionContentWidget,
            )
          : mentionContentWidget,
    );

    return content;
  }

  void _handleUserTap() {
    // Implement user tap action (e.g., show profile, start chat)
  }
}
