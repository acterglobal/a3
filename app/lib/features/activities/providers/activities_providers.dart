import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:riverpod/riverpod.dart';

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
  PushStyles.creation,
  PushStyles.redaction,
  PushStyles.titleChange,
  PushStyles.descriptionChange,
  PushStyles.otherChanges
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

final _spaceActivitiesProvider = AsyncNotifierProviderFamily<
  AsyncSpaceActivitiesNotifier,
  List<String>,
  String
>(() => AsyncSpaceActivitiesNotifier());

final activityProvider =
    AsyncNotifierProviderFamily<AsyncActivityNotifier, Activity?, String>(
      () => AsyncActivityNotifier(),
    );

final spaceActivitiesProvider = FutureProvider.family<List<Activity>, String>((
  ref,
  spaceId,
) async {
  final spaceActivities = await ref.watch(
    _spaceActivitiesProvider(spaceId).future,
  );
  final activities = await Future.wait(
    spaceActivities.map(
      (activityId) async =>
          await ref.watch(activityProvider(activityId).future),
    ),
  );
  //Remove null activities
  final acitivitiesList = activities.whereType<Activity>().toList();

  // Filter by supported activity types
  acitivitiesList.removeWhere((activity) {
    final activityType = PushStyles.values.asNameMap()[activity.typeStr()];
    return !supportedActivityTypes.contains(activityType);
  });

  //Sort by originServerTs
  acitivitiesList.sort(
    (a, b) => b.originServerTs().compareTo(a.originServerTs()),
  );
  return acitivitiesList;
});

final allActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final allSpacesList = ref.watch(spacesProvider);
  final activities = await Future.wait(
    allSpacesList.map(
      (space) async =>
          await ref.watch(spaceActivitiesProvider(space.getRoomIdStr()).future),
    ),
  );
  return activities.expand((x) => x).toList();
});

final activityDatesProvider = FutureProvider<List<DateTime>>((ref) async {
  final activities = await ref.watch(allActivitiesProvider.future);

  final uniqueDates = <DateTime>{};

  for (final activity in activities) {
    final activityDate =
        DateTime.fromMillisecondsSinceEpoch(
          activity.originServerTs(),
        ).toLocal();
    // Set time to midnight for consistent date comparison
    uniqueDates.add(
      DateTime(activityDate.year, activityDate.month, activityDate.day),
    );
  }

  return uniqueDates.toList()..sort((a, b) => b.compareTo(a));
});

final roomIdsByDateProvider = FutureProvider.family<List<String>, DateTime>((
  ref,
  date,
) async {
  final activities = await ref.watch(allActivitiesProvider.future);

  final roomIds = <String>{};

  for (final activity in activities) {
    final activityDate =
        DateTime.fromMillisecondsSinceEpoch(
          activity.originServerTs(),
        ).toLocal();
    final activityDateOnly = DateTime(
      activityDate.year,
      activityDate.month,
      activityDate.day,
    );

    if (activityDateOnly.isAtSameMomentAs(date)) {
      roomIds.add(activity.roomIdStr());
    }
  }

  return roomIds.toList();
});

final spaceActivitiesProviderByDate =
    FutureProvider.family<List<Activity>, ({String roomId, DateTime date})>((
      ref,
      params,
    ) async {
      final activities = await ref.watch(
        spaceActivitiesProvider(params.roomId).future,
      );

      return activities.where((activity) {
        // First check if activity matches the date
        final activityDate =
            DateTime.fromMillisecondsSinceEpoch(
              activity.originServerTs(),
            ).toLocal();
        final activityDateOnly = DateTime(
          activityDate.year,
          activityDate.month,
          activityDate.day,
        );

        return activityDateOnly.isAtSameMomentAs(params.date);
      }).toList();
    });
