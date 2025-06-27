import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_date_item_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildSpaceActivitiesSectionWidget(BuildContext context, WidgetRef ref) {
  final activityDates = ref.watch(activityDatesProvider);
  if (activityDates.isEmpty) return null;

  final isLoadingMore = ref.watch(isLoadingMoreActivitiesProvider);

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SectionHeader(
        title: L10n.of(context).spaceActivities,
        showSectionBg: false,
        isShowSeeAllButton: false,
      ),
      ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activityDates.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return ActivityDateItemWidget(activityDate: activityDates[index]);
        },
      ),
      // Show loading indicator when loading more
      if (isLoadingMore)
        Container(
          padding: const EdgeInsets.all(80.0),
          child: const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Loading more activities...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      // Add some bottom spacing
      const SizedBox(height: 16),
    ],
  );
}
