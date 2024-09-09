import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:extension_nullable/extension_nullable.dart';
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
    final roomId = manager.roomIdStr();
    final userId = comment.sender().toString();
    final msgContent = comment.msgContent();
    final commentTime = DateTime.fromMillisecondsSinceEpoch(
      comment.originServerTs(),
      isUtc: true,
    );
    final time = commentTime.toLocal().timeago();
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
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
              avatarInfo.displayName ?? userId,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: avatarInfo.displayName.map((p0) => Text(userId)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                msgContent.formattedBody().map((p0) => RenderHtml(text: p0)) ??
                    Text(msgContent.body()),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              time.toString(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
