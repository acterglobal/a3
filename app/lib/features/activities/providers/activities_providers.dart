import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return HasActivities.none;
});
