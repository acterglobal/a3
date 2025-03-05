import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities/activity_item_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildSpaceActivitiesWidget(
  BuildContext context,
  WidgetRef ref,
) {
  final activities = ref.watch(allActivitiesProvider).valueOrNull;
  if (activities == null || activities.isEmpty) return null;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SectionHeader(
        title: L10n.of(context).spaceActivities,
        showSectionBg: false,
        isShowSeeAllButton: false,
      ),
      ListView.builder(
        itemCount: activities.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final activityId = activities[index];
          final activity = ref.watch(activityProvider(activityId)).valueOrNull;
          if (activity == null) return const SizedBox.shrink();
          return ActivityItemWidget(activity: activity);
        },
      ),
    ],
  );
}
