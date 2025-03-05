import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/time_ago_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//Main container for all activity item widgets
class ActivityItemContainerWidget extends StatelessWidget {
  final String actionTitle;
  final String? objectInfo;
  final Widget userInfoWidget;
  final int originServerTs;

  const ActivityItemContainerWidget({
    super.key,
    required this.actionTitle,
    this.objectInfo,
    required this.userInfoWidget,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context) {
    final actionTitleStyle = Theme.of(context).textTheme.labelMedium;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(actionTitle, style: actionTitleStyle),
                if (objectInfo != null) ...[
                  const SizedBox(width: 6),
                  Text(objectInfo!, style: actionTitleStyle),
                ],
              ],
            ),
            const SizedBox(height: 6),
            userInfoWidget,
            TimeAgoWidget(originServerTs: originServerTs),
          ],
        ),
      ),
    );
  }
}

//Container for the user info and subtitle
class ActivityUserInfoContainerWidget extends ConsumerWidget {
  final Activity activity;
  final String subtitle;

  const ActivityUserInfoContainerWidget({
    super.key,
    required this.activity,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = activity.senderIdStr();
    final roomId = activity.roomIdStr();
    final memberInfo =
        ref.watch(memberAvatarInfoProvider((roomId: roomId, userId: userId)));
    return ListTile(
      horizontalTitleGap: 6,
      contentPadding: EdgeInsets.zero,
      leading: ActerAvatar(options: AvatarOptions.DM(memberInfo, size: 32)),
      title: Text(memberInfo.displayName ?? userId),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
