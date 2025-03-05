import 'package:acter/features/activities/widgets/space_activities/item_widgets/activity_item_container_widgets.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';

class ActivityCommentItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityCommentItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    final objectEmoji = activityObject?.emoji();
    final objectTitle = activityObject?.title();

    return ActivityItemContainerWidget(
      actionTitle: '${PushStyles.comment.emoji} Commented on',
      objectInfo: '$objectEmoji $objectTitle}',
      userInfoWidget: ActivityUserInfoContainerWidget(
        userId: activity.senderIdStr(),
        roomId: activity.roomIdStr(),
        subtitle: activity.msgContent()?.body() ?? '',
      ),
      originServerTs: activity.originServerTs(),
    );
  }
}
