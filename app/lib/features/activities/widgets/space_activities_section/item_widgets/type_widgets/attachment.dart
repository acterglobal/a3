import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';

class ActivityAttachmentItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityAttachmentItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    final name = activity.name();
    final subType = activity.subTypeStr();
    final objectEmoji = activityObject?.emoji();
    final objectTitle = activityObject?.title();

    return ActivityUserCentricItemContainerWidget(
      actionTitle: '${PushStyles.attachment.emoji} Added attachment on',
      actionObjectInfo: '$objectEmoji $objectTitle',
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: '$subType : $name',
      originServerTs: activity.originServerTs(),
    );
  }
}
