import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/time_ago_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            buidlActionInfoUI(context, ref),
            buildUserInfoUI(context, ref),
            TimeAgoWidget(originServerTs: activity.originServerTs()),
          ],
        ),
      ),
    );
  }

  Widget buidlActionInfoUI(BuildContext context, WidgetRef ref) {
    final activityObject = activity.object();
    final actionTitleStyle = Theme.of(context).textTheme.labelMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(getActivityActionTitle(), style: actionTitleStyle),
        const SizedBox(width: 6),
        Text(
          activityObject != null ? parentPart(activityObject) : '',
          style: actionTitleStyle,
        ),
      ],
    );
  }

  String getActivityActionTitle() {
    final activityType = activity.typeStr();
    final pushStyle = PushStyles.values.asNameMap()[activityType];
    switch (pushStyle) {
      case PushStyles.comment:
        return '${PushStyles.comment.emoji} Commented on';
      case PushStyles.reaction:
        return '${PushStyles.reaction.emoji} Reacted to';
      case PushStyles.attachment:
        return '${PushStyles.attachment.emoji} Attached on';
      case PushStyles.references:
        return '${PushStyles.references.emoji} Referenced on';
      default:
        return '';
    }
  }

  Widget buildUserInfoUI(BuildContext context, WidgetRef ref) {
    final userId = activity.senderIdStr();
    final roomId = activity.roomIdStr();
    final memberInfo =
        ref.watch(memberAvatarInfoProvider((roomId: roomId, userId: userId)));
    final messageContent = activity.msgContent()?.body() ?? '';
    return ListTile(
      horizontalTitleGap: 6,
      contentPadding: EdgeInsets.zero,
      leading: ActerAvatar(options: AvatarOptions.DM(memberInfo, size: 32)),
      title: Text(memberInfo.displayName ?? userId),
      subtitle: Text(
        messageContent,
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
