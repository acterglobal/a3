import 'package:acter/features/activities/actions/activity_item_click_action.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_bigger_visual_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityTaskAddItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityTaskAddItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    return ActivityBiggerVisualContainerWidget(
      onTap: () => onTapActivityItem(context, activityObject),
      actionIcon: Icons.add_circle_outline,
      actionTitle: L10n.of(context).addedTaskOn,
      target: activityObject?.title() ?? '',
      subtitle: Text(
        activity.name() ?? '',
        style: Theme.of(context).textTheme.labelSmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
