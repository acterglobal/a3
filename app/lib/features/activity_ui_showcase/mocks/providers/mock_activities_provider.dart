import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activity_ui_showcase/mocks/data/mock_activities_list_generator.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

final mockActivitiesProvider = Provider<List<MockActivity>>((ref) {
  return mockActivitiesListGenerator;
});

// Family provider to get individual mock activity by ID
final mockActivityProvider = Provider.family<MockActivity?, String>((ref, activityId) {
  final mockActivities = ref.watch(mockActivitiesProvider);
  try {
    return mockActivities.firstWhere((activity) => activity.mockActivityId == activityId);
  } catch (e) {
    return null; // Return null if not found
  }
});

final mockActivitiesDatesProvider = Provider<List<DateTime>>((ref) {
  final mockActivities = ref.watch(mockActivitiesProvider);
  return mockActivities.map((e) => getActivityDate(e.originServerTs())).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
});

// Mock version of activitiesByDateProvider for showcase
final mockActivitiesByDateProvider = Provider.family<List<MockActivity>, DateTime>((ref, date) {
  final mockActivities = ref.watch(mockActivitiesProvider);
  return mockActivities.where((activity) => 
    getActivityDate(activity.originServerTs()).isAtSameMomentAs(date)).toList();
});

// Mock version of consecutiveGroupedActivitiesProvider for showcase
final mockConsecutiveGroupedActivitiesProvider = Provider.family<List<RoomActivitiesInfo>, DateTime>((ref, date) {
  final activitiesForDate = ref.watch(mockActivitiesByDateProvider(date));
  
  // Sort by time descending
  final sortedActivities = activitiesForDate.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));

  // Group consecutive activities by roomId
  final groups = <RoomActivitiesInfo>[];
  
  for (final activity in sortedActivities) {
    final roomId = activity.roomIdStr();
    
    if (groups.isNotEmpty && groups.last.roomId == roomId) {
      // Add to existing group
      final lastGroup = groups.last;
      groups[groups.length - 1] = (roomId: roomId, activities: [...lastGroup.activities, activity as Activity]);
    } else {
      // Create new group
      groups.add((roomId: roomId, activities: [activity as Activity]));
    }
  }
  
  return groups;
});