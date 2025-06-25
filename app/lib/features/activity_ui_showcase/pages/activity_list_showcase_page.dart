import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_widget.dart';
import 'package:acter/features/activity_ui_showcase/mocks/providers/mock_activities_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityListShowcasePage extends ConsumerWidget {
  const ActivityListShowcasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final sortedDates = ref.watch(mockActivitiesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.spaceActivities),
      ),
      body: SingleChildScrollView(
        child: _buildMockActivitiesSection(context, ref, sortedDates),
      ),
    );
  }

  Widget _buildMockActivitiesSection(
    BuildContext context, 
    WidgetRef ref, 
    List<Activity> activities
  ) {

    if (activities.isEmpty) {
      return const Center(child: Text('No mock activities available'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: activities.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ActivityItemWidget(activity: activity);
          },
        ),
      ],
    );
  }
} 