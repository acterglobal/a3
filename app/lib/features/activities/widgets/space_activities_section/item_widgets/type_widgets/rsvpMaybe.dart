import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityEventRSVPMayBeItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityEventRSVPMayBeItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();

    return ActivityUserCentricItemContainerWidget(
      actionIcon: Icons.question_mark,
      actionTitle: L10n.of(context).mayBe,
      actionIconColor: Colors.grey.shade400,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
