import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_membership_container_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityMembershipItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityMembershipItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    return ActivityMembershipItemContainerWidget(
      activityObject: activityObject,
      userId: activity.membershipContent()?.userId().toString() ?? '',
      roomId: activity.roomIdStr(),
      senderId: activity.senderIdStr(),
      originServerTs: activity.originServerTs(),
      membershipContent: activity.membershipContent(),
    );
  }
}
