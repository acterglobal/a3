import 'package:acter/features/activity_ui_showcase/mocks/providers/mock_activities_provider.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_date_item_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/widgets/info_widget.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityListShowcasePage extends ConsumerWidget {
  const ActivityListShowcasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    
    // Debug: Check what mock data we have
    final mockActivities = ref.watch(mockAllActivitiesProvider);
    print('🔍 Mock activities count: ${mockActivities.length}');
    
    // Calculate dates directly from mock data
    final uniqueDates = mockActivities.map(getActivityDate).toSet();
    final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));
    print('🔍 Direct calculation - Unique dates: ${sortedDates.map((d) => d.toString()).join(', ')}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.spaceActivities),
      ),  
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildMockActivitiesSection(context, ref, mockActivities, sortedDates),
        ),
      ),
    );
  }

  Widget _buildMockActivitiesSection(
    BuildContext context, 
    WidgetRef ref, 
    List<Activity> activities, 
    List<DateTime> dates
  ) {
    final lang = L10n.of(context);
    
    if (dates.isEmpty) {
      return const Center(child: Text('No mock activities available'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: lang.spaceActivities,
          showSectionBg: false,
          isShowSeeAllButton: false,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InfoWidget(
            title: lang.betaVersion,
            subTitle: lang.spaceAcitivitiesBetaInfo,
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => openLink(
              ref: ref,
              target: 'https://github.com/acterglobal/a3/issues/2597',
              lang: lang,
            ),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: dates.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final date = dates[index];
            return ProviderScope(
              overrides: [
                consecutiveGroupedActivitiesProvider.overrideWith((ref, queryDate) {
                  if (!queryDate.isAtSameMomentAs(date)) return [];
                  
                  // Filter activities by date
                  final activitiesForDate = activities.where((activity) => 
                    getActivityDate(activity).isAtSameMomentAs(date)).toList();
                  
                  // Sort by time descending
                  final sortedActivities = activitiesForDate.toList()
                    ..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));

                  // Group consecutive activities by roomId
                  final groups = <({String roomId, List<Activity> activities})>[];
                  
                  for (final activity in sortedActivities) {
                    final roomId = activity.roomIdStr();
                    
                    if (groups.isNotEmpty && groups.last.roomId == roomId) {
                      // Add to existing group
                      final lastGroup = groups.last;
                      groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity]);
                    } else {
                      // Create new group
                      groups.add((roomId: roomId, activities: [activity]));
                    }
                  }
                  
                  print('🔍 Groups for date $date: ${groups.length}');
                  return groups;
                }),
              ],
              child: ActivityDateItemWidget(activityDate: date),
            );
          },
        ),
      ],
    );
  }
} 