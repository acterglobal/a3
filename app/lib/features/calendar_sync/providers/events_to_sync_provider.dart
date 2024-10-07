//ALL UPCOMING EVENTS
import 'package:acter/features/events/actions/get_event_type.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef EventAndRsvp = ({CalendarEvent event, RsvpStatusTag? rsvp});

final eventsToSyncProvider = FutureProvider.autoDispose((ref) async {
  // fetch all from all spaces
  final allEventList = await ref.watch(allEventListProvider(null).future);
  final upcomingAndOngoing = allEventList.where((event) {
    final eventType = getEventType(event);
    return eventType == EventFilters.upcoming ||
        eventType == EventFilters.ongoing;
  });
  final List<EventAndRsvp> toSync = [];

  for (final event in upcomingAndOngoing) {
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
