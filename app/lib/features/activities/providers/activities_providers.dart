import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:riverpod/riverpod.dart';

enum HasActivities {
  urgent,
  important,
  unread,
  read,
  none,
}

final hasActivitiesProvider = StateProvider((ref) {
  final invitations = ref.watch(invitationListProvider);
  if (invitations.isNotEmpty) {
    return HasActivities.important;
  }
  final syncStatus = ref.watch(syncStateProvider);
  if (syncStatus.errorMsg != null) {
    return HasActivities.important;
  }
  return HasActivities.none;
});
