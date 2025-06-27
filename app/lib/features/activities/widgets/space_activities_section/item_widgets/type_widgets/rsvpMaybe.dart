import 'package:acter/features/activities/actions/activity_item_click_action.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_individual_action_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityEventRSVPMayBeItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityEventRSVPMayBeItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();

    return ActivityIndividualActionContainerWidget(
      onTap: () => onTapActivityItem(context, activityObject),
      target: activityObject?.title() ?? '',
      actionIcon: Icons.question_mark,
      actionTitle: L10n.of(context).mayBe,
      actionIconBgColor: Theme.of(context).cardColor,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
