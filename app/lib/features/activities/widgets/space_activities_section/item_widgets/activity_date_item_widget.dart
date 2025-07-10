import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/space_activities_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityDateItemWidget extends ConsumerWidget {
  final DateTime activityDate;

  const ActivityDateItemWidget({super.key, required this.activityDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch grouped activities for a given date
    final groupedActivitiesList = ref.watch(activitiesByDateProvider(activityDate));

    if (groupedActivitiesList.isEmpty) return const SizedBox.shrink();

    String? previousDateText;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: groupedActivitiesList.length,
      itemBuilder: (context, index) {
        final roomActivities = groupedActivitiesList[index];

        final activityDateText = jiffyDateForActvity(
          context,
          roomActivities.activities.first.originServerTs(),
        );

        // Only show the date header if it differs from the previous one
        final showDateHeader = activityDateText != previousDateText;
        previousDateText = activityDateText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDateHeader)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  activityDateText,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),

            SpaceActivitiesItemWidget(
              date: activityDate,
              roomId: roomActivities.roomId,
              activities: roomActivities.activities,
            ),
          ],
        );
      },
    );
  }
}
