import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/space_activities_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityDateItemWidget extends ConsumerWidget {
  final DateTime date;

  const ActivityDateItemWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(consecutiveGroupedActivitiesProvider(date));

    if (groups.isEmpty) return const SizedBox.shrink();

    String? lastPeriod;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final period = jiffyDateForActvity(context, group.activities.first.originServerTs());
        final showChip = period != lastPeriod;
        lastPeriod = period;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showChip)
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
                  period,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            SpaceActivitiesItemWidget(
              date: date,
              roomId: group.roomId,
              activities: group.activities,
            ),
          ],
        );
      },
    );
  }
}
