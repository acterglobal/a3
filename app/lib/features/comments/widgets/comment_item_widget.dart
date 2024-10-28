import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
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
                  messageContentUI(context),
                  const SizedBox(height: 4),
                  messageTimeUI(context),
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
    final userId = comment.sender().toString();
    final displayName = avatarInfo.displayName;
    final displayNameTextStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.bold);
    final usrNameTextStyle = Theme.of(context).textTheme.labelMedium;

    return Wrap(
      children: [
        Text(displayName ?? userId, style: displayNameTextStyle),
        const SizedBox(width: 8),
        if (displayName != null) Text(userId, style: usrNameTextStyle),
      ],
    );
  }

  Widget messageContentUI(BuildContext context) {
    final msgContent = comment.msgContent();
    final formatted = msgContent.formattedBody();
    final messageTextStyle = Theme.of(context).textTheme.bodyMedium;

    return formatted != null
        ? RenderHtml(text: formatted, defaultTextStyle: messageTextStyle)
        : Text(msgContent.body(), style: messageTextStyle);
  }

  Widget messageTimeUI(BuildContext context) {
    final commentTime = DateTime.fromMillisecondsSinceEpoch(
      comment.originServerTs(),
      isUtc: true,
    );
    final time = commentTime.toLocal().timeago();
    return Text(
      time,
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
