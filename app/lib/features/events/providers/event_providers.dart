import 'package:acter/features/events/event_utils/event_utils.dart';
import 'package:acter/features/events/providers/notifiers/event_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

//SINGLE CALENDER EVENT DETAILS PROVIDER
final calendarEventProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncCalendarEventNotifier, ffi.CalendarEvent, String>(
  () => AsyncCalendarEventNotifier(),
);

//MY RSVP STATUS PROVIDER
final myRsvpStatusProvider = FutureProvider.family
    .autoDispose<ffi.OptionRsvpStatus, String>((ref, calendarId) async {
  final event = await ref.watch(calendarEventProvider(calendarId).future);
  return await event.respondedByMe();
});

//SpaceId == null : GET LIST OF ALL PINs
//SpaceId != null : GET LIST OF SPACE PINs
final allEventListProvider = AsyncNotifierProvider.family<EventListNotifier,
    List<ffi.CalendarEvent>, String?>(
  () => EventListNotifier(),
);

//ALL ONGOING EVENTS
final ongoingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, params) async {
  final allEventList = await ref.watch(allEventListProvider(params).future);
  List<ffi.CalendarEvent> ongoingEventList = [];
  for (final event in allEventList) {
    if (getEventType(event) == EventFilters.ongoing) {
      ongoingEventList.add(event);
    }
  }
  return sortEventListAscTime(ongoingEventList);
});

//MY ONGOING EVENTS
final myOngoingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, params) async {
  List<ffi.CalendarEvent> allOngoingEventList =
      await ref.watch(ongoingEventListProvider(params).future);
  List<ffi.CalendarEvent> myOngoingEventList = [];
  for (final event in allOngoingEventList) {
    final myRsvpStatus = await ref
        .watch(myRsvpStatusProvider(event.eventId().toString()).future);
    if (myRsvpStatus.statusStr() != null && myRsvpStatus.statusStr() == 'yes') {
      myOngoingEventList.add(event);
    }
  }
  return sortEventListAscTime(myOngoingEventList);
});

//ALL UPCOMING EVENTS
final upcomingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, params) async {
  final allEventList = await ref.watch(allEventListProvider(params).future);
  List<ffi.CalendarEvent> upcomingEventList = [];
  for (final event in allEventList) {
    if (getEventType(event) == EventFilters.upcoming) {
      upcomingEventList.add(event);
    }
  }
  return sortEventListAscTime(upcomingEventList);
});

//MY UPCOMING EVENTS
final myUpcomingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, params) async {
  List<ffi.CalendarEvent> allUpcomingEventList =
      await ref.watch(upcomingEventListProvider(params).future);
  List<ffi.CalendarEvent> myUpcomingEventList = [];
  for (final event in allUpcomingEventList) {
    final myRsvpStatus = await ref
        .watch(myRsvpStatusProvider(event.eventId().toString()).future);
    if (myRsvpStatus.statusStr() != null && myRsvpStatus.statusStr() == 'yes') {
      myUpcomingEventList.add(event);
    }
  }
  return sortEventListAscTime(myUpcomingEventList);
});

//ALL PAST EVENTS
final pastEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, params) async {
  final allEventList = await ref.watch(allEventListProvider(params).future);
  List<ffi.CalendarEvent> paseEventList = [];
  for (final event in allEventList) {
    if (getEventType(event) == EventFilters.past) {
      paseEventList.add(event);
    }
  }
  return sortEventListDscTime(paseEventList);
});

//MY PAST EVENTS
final myPastEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, params) async {
  List<ffi.CalendarEvent> allPastEventList =
      await ref.watch(pastEventListProvider(params).future);
  List<ffi.CalendarEvent> myPastEventList = [];
  for (final event in allPastEventList) {
    final myRsvpStatus = await ref
        .watch(myRsvpStatusProvider(event.eventId().toString()).future);
    if (myRsvpStatus.statusStr() != null && myRsvpStatus.statusStr() == 'yes') {
      myPastEventList.add(event);
    }
  }
  return sortEventListDscTime(myPastEventList);
});

//MY EVENTS (ONGOING+UPCOMING)
final myEventsList = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, params) async {
  final myOngoingEvents =
      await ref.watch(myOngoingEventListProvider(params).future);
  final myUpcomingEvents =
      await ref.watch(myUpcomingEventListProvider(params).future);
  List<ffi.CalendarEvent> myEventsList = [];
  myEventsList.addAll(myOngoingEvents);
  myEventsList.addAll(myUpcomingEvents);
  return myEventsList;
});

//EVENT FILTERS
enum EventFilters {
  all,
  ongoing,
  upcoming,
  past,
}

final eventFilerProvider =
    StateProvider.autoDispose<EventFilters>((ref) => EventFilters.all);

//SEARCH EVENTS
typedef EventListSearchParams = ({String? spaceId, String searchText});

final eventListSearchFilterProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, EventListSearchParams>(
        (ref, params) async {
  //Declare filtered event list
  List<ffi.CalendarEvent> filteredEventList = [];

  //Get different event list
  List<ffi.CalendarEvent> ongoingEventList =
      await ref.watch(ongoingEventListProvider(params.spaceId).future);
  List<ffi.CalendarEvent> upcomingEventList =
      await ref.watch(upcomingEventListProvider(params.spaceId).future);
  List<ffi.CalendarEvent> pastEventList =
      await ref.watch(pastEventListProvider(params.spaceId).future);

  //Filter events based on the selection
  EventFilters eventFilter = ref.watch(eventFilerProvider);
  switch (eventFilter) {
    case EventFilters.ongoing:
      filteredEventList = ongoingEventList;
    case EventFilters.upcoming:
      filteredEventList = upcomingEventList;
    case EventFilters.past:
      filteredEventList = pastEventList;
    default:
      {
        filteredEventList.addAll(ongoingEventList);
        filteredEventList.addAll(upcomingEventList);
        filteredEventList.addAll(pastEventList);
      }
  }

  //Apply search on filtered event list
  List<ffi.CalendarEvent> searchedFilteredEventList = [];
  if (params.searchText.isNotEmpty) {
    for (final event in filteredEventList) {
      bool isContainSearchTerm =
          event.title().toLowerCase().contains(params.searchText.toLowerCase());
      if (isContainSearchTerm) {
        searchedFilteredEventList.add(event);
      }
    }
    return searchedFilteredEventList;
  }

  return filteredEventList;
});
