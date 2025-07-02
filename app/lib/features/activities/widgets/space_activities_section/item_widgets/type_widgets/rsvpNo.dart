import 'package:acter/features/activities/actions/activity_item_click_action.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_individual_action_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityEventRSVPNoItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityEventRSVPNoItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();

    return ActivityIndividualActionContainerWidget(
      onTap: () => onTapActivityItem(context, activityObject),
      target: activityObject?.title() ?? '',
      actionIcon: Icons.close_rounded,
      actionTitle: L10n.of(context).notGoingTo,
      actionIconBgColor: Colors.red.shade400,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
