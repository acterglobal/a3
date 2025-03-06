import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/time_ago_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//Main container for all activity item widgets
class ActivityUserCentricItemContainerWidget extends ConsumerWidget {
  final String actionTitle;
  final String? actionObjectInfo;
  final String userId;
  final String roomId;
  final String? subtitle;
  final int originServerTs;

  const ActivityUserCentricItemContainerWidget({
    super.key,
    required this.actionTitle,
    this.actionObjectInfo,
    required this.userId,
    required this.roomId,
    this.subtitle,
    required this.originServerTs,
  });

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
            buildActionInfoUI(context),
            const SizedBox(height: 6),
            buildUserInfoUI(context, ref),
            TimeAgoWidget(originServerTs: originServerTs),
          ],
        ),
      ),
    );
  }

  Widget buildActionInfoUI(BuildContext context) {
    final actionTitleStyle = Theme.of(context).textTheme.labelMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(actionTitle, style: actionTitleStyle),
        if (actionObjectInfo != null) ...[
          const SizedBox(width: 6),
          Text(actionObjectInfo!, style: actionTitleStyle),
        ],
      ],
    );
  }

  Widget buildUserInfoUI(BuildContext context, WidgetRef ref) {
    final memberInfo =
        ref.watch(memberAvatarInfoProvider((roomId: roomId, userId: userId)));
    return ListTile(
      horizontalTitleGap: 6,
      contentPadding: EdgeInsets.zero,
      leading: ActerAvatar(options: AvatarOptions.DM(memberInfo, size: 32)),
      title: Text(memberInfo.displayName ?? userId),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : const SizedBox.shrink(),
    );
  }
}
