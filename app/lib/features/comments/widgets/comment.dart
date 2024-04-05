import 'package:acter/common/widgets/render_html.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentWidget extends ConsumerWidget {
  final Comment comment;

  const CommentWidget({super.key, required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msgContent = comment.msgContent();
    final formatted = msgContent.formattedBody();
    var commentTime = DateTime.fromMillisecondsSinceEpoch(comment.originServerTs());
    final time = commentTime.timeago();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: ActerAvatar(
              mode: DisplayMode.DM,
              avatarInfo: AvatarInfo(uniqueId: comment.sender().toString()),
            ),
            title: Text(
              comment.sender().toString(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: Text(comment.sender().toString()),
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
            child: Text(time.toString(),style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
