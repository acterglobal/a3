import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
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

    return ActivityUserCentricItemContainerWidget(
      actionTitle:
          '${PushStyles.comment.emoji} ${L10n.of(context).commentedOn}',
      actionObjectInfo: '$objectEmoji $objectTitle',
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: activity.msgContent()?.body() ?? '',
      originServerTs: activity.originServerTs(),
    );
  }
}
