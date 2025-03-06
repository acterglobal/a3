import 'package:acter/features/activities/widgets/space_activities/item_widgets/activity_item_container_widgets.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';

class ActivityReferencesItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityReferencesItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    final objectEmoji = activityObject?.emoji();
    final objectTitle = activityObject?.title();

    return ActivityUserCentricItemContainerWidget(
      actionTitle: '${PushStyles.references.emoji} Added references on',
      actionObjectInfo: '$objectEmoji $objectTitle',
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: getRefPreview(),
      originServerTs: activity.originServerTs(),
    );
  }

  String getRefPreview() {
    final refDetails = activity.refDetails();
    final refTitle = refDetails?.title();
    final refType = refDetails?.typeStr();
    final objectType = SpaceObjectTypes.values.asNameMap()[refType];
    switch (objectType) {
      case SpaceObjectTypes.news:
        return '${SpaceObjectTypes.news.emoji} $refTitle';
      case SpaceObjectTypes.pin:
        return '${SpaceObjectTypes.pin.emoji} $refTitle';
      case SpaceObjectTypes.event:
        return '${SpaceObjectTypes.event.emoji} $refTitle';
      case SpaceObjectTypes.taskList:
        return '${SpaceObjectTypes.taskList.emoji} $refTitle';
      case SpaceObjectTypes.taskItem:
        return '${SpaceObjectTypes.taskItem.emoji} $refTitle';
      default:
        return '${PushStyles.references.emoji} $refTitle';
    }
  }
}
