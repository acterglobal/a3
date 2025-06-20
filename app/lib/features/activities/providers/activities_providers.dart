import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supportedActivityTypes = [
  PushStyles.comment,
  PushStyles.reaction,
  PushStyles.attachment,
  PushStyles.references,
  PushStyles.eventDateChange,
  PushStyles.rsvpYes,
  PushStyles.rsvpMaybe,
  PushStyles.rsvpNo,
  PushStyles.taskAdd,
  PushStyles.taskComplete,
  PushStyles.taskReOpen,
  PushStyles.taskAccept,
  PushStyles.taskDecline,
  PushStyles.taskDueDateChange,
  PushStyles.roomName,
  PushStyles.roomTopic,
  PushStyles.roomAvatar,
  PushStyles.creation,
  PushStyles.titleChange,
  PushStyles.descriptionChange,
  PushStyles.otherChanges,
  PushStyles.invitationAccepted,
  PushStyles.invitationRejected,
  PushStyles.invited,
  PushStyles.joined,
  PushStyles.invitationRevoked,
  PushStyles.knockAccepted,
  PushStyles.knockRetracted,
  PushStyles.knockDenied,
  PushStyles.left,
  PushStyles.kicked,
  PushStyles.kickedAndBanned,
  PushStyles.knocked,
  PushStyles.banned,
  PushStyles.unbanned,
];

final hasActivitiesProvider = StateProvider((ref) {
  final invitations = ref.watch(invitationListProvider).valueOrNull ?? [];
  if (invitations.isNotEmpty) {
    return UrgencyBadge.urgent;
  }
  final syncStatus = ref.watch(syncStateProvider);
  if (syncStatus.errorMsg != null) {
    return UrgencyBadge.important;
  }
  if (ref.watch(hasUnconfirmedEmailAddresses)) {
    return UrgencyBadge.important;
  }
  return UrgencyBadge.none;
});

final hasUnconfirmedEmailAddresses = StateProvider(
  (ref) =>
      ref.watch(emailAddressesProvider).valueOrNull?.unconfirmed.isNotEmpty ==
      true,
);

final allActivitiesProvider =
    AsyncNotifierProvider<AllActivitiesNotifier, List<Activity>>(
  AllActivitiesNotifier.new,
);

// Helper function to filter activities by date
List<Activity> _filterActivitiesByDate(List<Activity> activities, DateTime date) {
  return activities.where((activity) => getActivityDate(activity).isAtSameMomentAs(date)).toList();
}

final activityDatesProvider = Provider<List<DateTime>>((ref) {
  final activities = ref.watch(allActivitiesProvider).valueOrNull;
  if (activities == null || activities.isEmpty) return [];
  
  final uniqueDates = activities.map(getActivityDate).toSet();
  return uniqueDates.toList()..sort((a, b) => b.compareTo(a));
});

// Base provider for activities filtered by date
final activitiesByDateProvider = Provider.family<List<Activity>, DateTime>((ref, date) {
  final allActivities = ref.watch(allActivitiesProvider).valueOrNull ?? [];
  return _filterActivitiesByDate(allActivities, date);
});

// Provider for consecutive grouped activities using records 
final consecutiveGroupedActivitiesProvider = Provider.family<List<({String roomId, List<Activity> activities})>, DateTime>((ref, date) {
  final activitiesForDate = ref.watch(activitiesByDateProvider(date));
  
  // Sort by time descending
  final sortedActivities = activitiesForDate.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));

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
  
  return groups;
});

