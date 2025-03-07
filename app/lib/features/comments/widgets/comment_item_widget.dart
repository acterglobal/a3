import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/message_content_widget.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentItemWidget extends ConsumerWidget {
  final Comment comment;
  final CommentsManager manager;

  const CommentItemWidget({
    super.key,
    required this.comment,
    required this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomID = manager.roomIdStr();
    final userId = comment.sender().toString();
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomID, userId: userId)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          userAvatarUI(context, avatarInfo),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  userNameUI(context, avatarInfo),
                  MessageContentWidget(
                    msgContent: comment.msgContent(),
                    roomId: roomID,
                  ),
                  const SizedBox(height: 4),
                  TimeAgoWidget(originServerTs: comment.originServerTs()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget userAvatarUI(BuildContext context, AvatarInfo avatarInfo) {
    return ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 18));
  }

  Widget userNameUI(BuildContext context, AvatarInfo avatarInfo) {
    final userId = avatarInfo.uniqueId;
    final displayName = avatarInfo.displayName;
    final displayNameTextStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold);
    return Wrap(
      children: [
        // display name
        Text(displayName ?? userId, style: displayNameTextStyle),
        const SizedBox(width: 8),
        if (displayName != null)
          Text(
            userId, // and username if we have a display name
            style: Theme.of(context).textTheme.labelMedium,
          ),
      ],
    );
  }
}
