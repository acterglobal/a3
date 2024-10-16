import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentWidget extends ConsumerWidget {
  final Comment comment;
  final CommentsManager manager;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomID = manager.roomIdStr();
    final userId = comment.sender().toString();
    final msgContent = comment.msgContent();
    final formatted = msgContent.formattedBody();
    final commentTime = DateTime.fromMillisecondsSinceEpoch(
      comment.originServerTs(),
      isUtc: true,
    );
    final time = commentTime.toLocal().timeago();
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomID, userId: userId)),
    );

    final displayName = avatarInfo.displayName;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: ActerAvatar(
              options: AvatarOptions.DM(
                avatarInfo,
                size: 18,
              ),
            ),
            title: Text(
              displayName ?? userId,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: displayName == null ? null : Text(userId),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: formatted != null
                ? RenderHtml(
                    text: formatted,
                  )
                : Text(msgContent.body()),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
