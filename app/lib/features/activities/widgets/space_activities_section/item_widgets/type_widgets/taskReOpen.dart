import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_individual_action_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityTaskReOpenItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityTaskReOpenItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();

    return ActivityIndividualActionContainerWidget(
      actionIcon: Icons.restart_alt,
      target: activityObject?.title() ?? '',
      actionTitle: L10n.of(context).reOpenedTask,
      actionIconColor: Colors.yellow.shade400,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
