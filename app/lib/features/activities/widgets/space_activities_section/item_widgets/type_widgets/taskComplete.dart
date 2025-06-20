import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_individual_action_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityTaskCompleteItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityTaskCompleteItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    return ActivityIndividualActionContainerWidget(
      actionIcon: Icons.done_all,
      actionTitle: L10n.of(context).completedTask,
      actionIconColor: Colors.blue.shade400,
      target: activityObject?.title() ?? '',
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
