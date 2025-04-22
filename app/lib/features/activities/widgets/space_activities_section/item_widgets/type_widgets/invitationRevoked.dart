import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityInvitationRevokedItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityInvitationRevokedItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    return ActivityUserCentricItemContainerWidget(
      actionIcon: Icons.person_remove,
      actionTitle: activity.membershipContent()?.change() ?? '',
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
