//ALL UPCOMING EVENTS
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/room/providers/user_settings_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef EventAndRsvp = ({CalendarEvent event, RsvpStatusTag? rsvp});

final shouldSyncRoomProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, roomId) async {
  try {
    final settings = await ref.watch(roomUserSettingsProvider(roomId).future);
    return settings.includeCalSync();
  } on RoomNotFound {
    return false;
  }
});

final eventsToSyncProvider = FutureProvider.autoDispose((ref) async {
  // fetch all from all spaces
  final allEventList = await ref.watch(allEventListProvider(null).future);
  final upcomingAndOngoing = allEventList.where((event) {
    final eventType = ref.watch(eventTypeProvider(event));
    return (eventType == EventFilters.upcoming ||
        eventType == EventFilters.ongoing);
  });
  final List<EventAndRsvp> toSync = [];

  for (final event in upcomingAndOngoing) {
    if (!await ref.watch(shouldSyncRoomProvider(event.roomIdStr()).future)) {
      // we skip this one
      continue;
    }
    final eventId = event.eventId().toString();
    final myRsvpStatus = await ref.watch(myRsvpStatusProvider(eventId).future);
    if (myRsvpStatus != RsvpStatusTag.No) {
      // we sync all that aren’t denied yet
      final event = await ref.watch(
        calendarEventProvider(eventId).future,
      ); // ensure we are listening to updates of the events themselves
      toSync.add((event: event, rsvp: myRsvpStatus));
    }
  }
  return toSync;
});
