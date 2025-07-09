import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_date_item_widget.dart';
import 'package:acter/features/activity_ui_showcase/mocks/providers/mock_activities_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityListShowcasePage extends ConsumerWidget {
  const ActivityListShowcasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    
    return ProviderScope(
      overrides: [
        // Override real providers with mock ones
        activitiesByDateProvider.overrideWith((ref, date) {
          return ref.watch(mockConsecutiveGroupedActivitiesProvider(date));
        }),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.spaceActivities),
        ),
        body: SingleChildScrollView(
          child: _buildMockActivitiesSection(context, ref),
        ),
      ),
    );
  }

  Widget _buildMockActivitiesSection(
    BuildContext context, 
    WidgetRef ref
  ) {
    final sortedDates = ref.watch(mockActivitiesDatesProvider);

    if (sortedDates.isEmpty) {
      return const Center(child: Text('No mock activities available'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sortedDates.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final activityDate = sortedDates[index];
            return ActivityDateItemWidget(activityDate: activityDate);
          },
        ),
      ],
    );
  }
} 