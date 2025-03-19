import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityTaskDueDateChangedItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityTaskDueDateChangedItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    final newDate = activity.newDate();

    String? newEventSchedule;

    if (newDate != null) {
      final startDate = getDateFormat(newDate);
      final startTime = getTimeFromDate(context, newDate);
      newEventSchedule = '$startDate - $startTime';
    }

    return ActivityUserCentricItemContainerWidget(
      actionIcon: Icons.access_time,
      actionTitle: L10n.of(context).rescheduled,
      actionIconColor: Colors.grey.shade400,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
      subtitle: Text(
        newEventSchedule ?? '',
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
