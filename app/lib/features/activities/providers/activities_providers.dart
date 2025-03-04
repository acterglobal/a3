import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

final hasActivitiesProvider = StateProvider((ref) {
  final invitations = ref.watch(invitationListProvider);
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

final spaceActivitiesProvider = AsyncNotifierProviderFamily<
    AsyncSpaceActivitiesNotifier, List<String>, String>(
  () => AsyncSpaceActivitiesNotifier(),
);

final allActivitiesProvider = FutureProvider<List<String>>(
  (ref) async {
    final allSpacesList = ref.watch(spacesProvider);
    final activities = await Future.wait(
      allSpacesList.map(
        (space) async => await ref
            .watch(spaceActivitiesProvider(space.getRoomIdStr()).future),
      ),
    );
    return activities.expand((x) => x).toList();
  },
);

final activityProvider =
    AsyncNotifierProviderFamily<AsyncActivityNotifier, Activity?, String>(
  () => AsyncActivityNotifier(),
);
