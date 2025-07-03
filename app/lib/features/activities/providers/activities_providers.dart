import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::activities::providers');

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

final activityProvider =
    AsyncNotifierProviderFamily<AsyncActivityNotifier, Activity?, String>(
      AsyncActivityNotifier.new,
    );

final allActivitiesProvider =
    AsyncNotifierProvider<AllActivitiesNotifier, List<String>>(
  AllActivitiesNotifier.new,
);

// Helper function to check if activity type is supported
bool isActivityTypeSupported(String activityType) {
  final pushStyle = PushStyles.values.asNameMap()[activityType];
  return pushStyle != null && supportedActivityTypes.contains(pushStyle);
}

// Helper function to get date-only DateTime from activity timestamp
DateTime getActivityDate(int timestamp) {
  final activityDate = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
  return DateTime(activityDate.year, activityDate.month, activityDate.day);
}

// Provider to get activities by id with filtering for supported types
final allActivitiesByIdProvider = FutureProvider<List<Activity>>((ref) async {

  final activityIds = await ref.watch(allActivitiesProvider.future);

  if (activityIds.isEmpty) return [];

  final activities = <Activity>[];
  for (final id in activityIds) {
    final activity = ref.watch(activityProvider(id)).valueOrNull;
    if (activity != null && isActivityTypeSupported(activity.typeStr())) {
      activities.add(activity);
    }
  }
  return activities;
});

// Provider to check if more activities can be loaded
final hasMoreActivitiesProvider = Provider<bool>((ref) {
  // Watch the provider to ensure we get updates when state changes
  ref.watch(allActivitiesProvider);
  final notifier = ref.read(allActivitiesProvider.notifier);
  return notifier.hasMoreData;
});

// Separate state provider for loading state that can be properly reactive
final isLoadingMoreStateProvider = StateProvider<bool>((ref) => false);

// Provider to check if currently loading more activities
final isLoadingMoreActivitiesProvider = Provider<bool>((ref) {
  return ref.watch(isLoadingMoreStateProvider);
});

// Simplified load more activities provider - just returns the action
final loadMoreActivitiesProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final activitiesNotifier = ref.read(allActivitiesProvider.notifier);
    final isCurrentlyLoading = ref.read(isLoadingMoreStateProvider);
    
    // Check if we can load more and aren't already loading
    if (!activitiesNotifier.hasMoreData || isCurrentlyLoading) {
      return;
    }
    
    // Set loading state to true
    ref.read(isLoadingMoreStateProvider.notifier).state = true;
    
    try {
      await activitiesNotifier.loadMore();
    } catch (e) { 
      _log.severe('Failed to load more activities', e);
    } finally {
      // Set loading state to false
      ref.read(isLoadingMoreStateProvider.notifier).state = false;
    }
  };
});

final activityDatesProvider = Provider<List<DateTime>>((ref) {
  final activities = ref.watch(allActivitiesByIdProvider).valueOrNull ?? [];

  if (activities.isEmpty) return [];

  final uniqueDates = activities.map((activity) => getActivityDate(activity.originServerTs())).toSet();
  return uniqueDates.toList()..sort((a, b) => b.compareTo(a));
});

// Base provider for activities filtered by date
final activitiesByDateProvider = Provider.family<List<Activity>, DateTime>((ref, date) {
  final activities = ref.watch(allActivitiesByIdProvider).valueOrNull ?? [];
  return activities.where((activity) =>
    getActivityDate(activity.originServerTs()).isAtSameMomentAs(date)).toList();
});

// Provider for consecutive grouped activities using records 
typedef RoomActivitiesInfo = ({String roomId, List<Activity> activities});

final consecutiveGroupedActivitiesProvider = Provider.family<List<RoomActivitiesInfo>, DateTime>((ref, date) {
  final activitiesForDate = ref.watch(activitiesByDateProvider(date));
  
  // Sort by time descending
  final sortedActivities = activitiesForDate.toList()..sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));

  // Group consecutive activities by roomId
  final groups = <RoomActivitiesInfo>[];
  
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

