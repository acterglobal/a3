import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityEventDateChangeItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityEventDateChangeItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    // Get the new date (if available)
    final newDate = activity.newDate();

    // Handle the case when newDate is null
    final day = newDate != null ? getDayFromDate(newDate) : null;
    final month = newDate != null ? getMonthFromDate(newDate) : null;
    final year = newDate != null ? getYearFromDate(newDate) : null;
    final startTime = newDate != null ? getTimeFromDate(context, newDate) : null;

    // Use a fallback message if newDate is null
    final dateText = newDate != null
        ? '$day $month, $year - $startTime'
        : ''; // Assuming noDateAvailable is a string in your localization.

    return ActivityUserCentricItemContainerWidget(
      actionIcon: Icons.access_time,
      actionTitle: L10n.of(context).rescheduled,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: Text(
        dateText,
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      originServerTs: activity.originServerTs(),
    );
  }
}
