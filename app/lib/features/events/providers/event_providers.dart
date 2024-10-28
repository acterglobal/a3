import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/actions/sort_event_list.dart';
import 'package:acter/features/events/providers/notifiers/event_notifiers.dart';
import 'package:acter/features/events/providers/notifiers/rsvp_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

//SINGLE CALENDER EVENT DETAILS PROVIDER
final calendarEventProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncCalendarEventNotifier, ffi.CalendarEvent, String>(
  () => AsyncCalendarEventNotifier(),
);

//MY RSVP STATUS PROVIDER
final myRsvpStatusProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncRsvpStatusNotifier, ffi.RsvpStatusTag?, String>(
  () => AsyncRsvpStatusNotifier(),
);

//SpaceId == null : GET LIST OF ALL PINs
//SpaceId != null : GET LIST OF SPACE PINs
final allEventListProvider = AsyncNotifierProvider.family<EventListNotifier,
    List<ffi.CalendarEvent>, String?>(
  () => EventListNotifier(),
);

//ALL ONGOING EVENTS
final bookmarkedEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
  final allEventList = await ref.watch(allEventListProvider(spaceId).future);
  final bookmarkedEventIds =
      ref.watch(bookmarkByTypeProvider(BookmarkType.events)).valueOrNull ?? [];
  List<ffi.CalendarEvent> bookmarkedEventList = allEventList.where((event) {
    return bookmarkedEventIds.contains(event.eventId().toString());
  }).toList();
  return sortEventListAscTime(bookmarkedEventList);
});

//ALL ONGOING EVENTS
final allOngoingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
  final allEventList = await ref.watch(allEventListProvider(spaceId).future);
  List<ffi.CalendarEvent> allOngoingEventList = allEventList
      .where(
        (event) => ref.watch(eventTypeProvider(event)) == EventFilters.ongoing,
      )
      .toList();
  return sortEventListAscTime(allOngoingEventList);
});

//MY ONGOING EVENTS
final myOngoingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
  List<ffi.CalendarEvent> allOngoingEventList =
      await ref.watch(allOngoingEventListProvider(spaceId).future);
  List<ffi.CalendarEvent> myOngoingEventList = [];
  for (final event in allOngoingEventList) {
    final myRsvpStatus = await ref
        .watch(myRsvpStatusProvider(event.eventId().toString()).future);
    if (myRsvpStatus == ffi.RsvpStatusTag.Yes) {
      myOngoingEventList.add(event);
    }
  }
  return myOngoingEventList;
});

//ALL UPCOMING EVENTS
final allUpcomingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
  final allEventList = await ref.watch(allEventListProvider(spaceId).future);
  List<ffi.CalendarEvent> allUpcomingEventList = allEventList
      .where(
        (event) => ref.watch(eventTypeProvider(event)) == EventFilters.upcoming,
      )
      .toList();
  return sortEventListAscTime(allUpcomingEventList);
});

//MY UPCOMING EVENTS
final myUpcomingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
  List<ffi.CalendarEvent> allUpcomingEventList =
      await ref.watch(allUpcomingEventListProvider(spaceId).future);
  List<ffi.CalendarEvent> myUpcomingEventList = [];
  for (final event in allUpcomingEventList) {
    final myRsvpStatus = await ref
        .watch(myRsvpStatusProvider(event.eventId().toString()).future);
    if (myRsvpStatus == ffi.RsvpStatusTag.Yes) {
      myUpcomingEventList.add(event);
    }
  }
  return myUpcomingEventList;
});

//ALL PAST EVENTS
final allPastEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
  final allEventList = await ref.watch(allEventListProvider(spaceId).future);
  List<ffi.CalendarEvent> allPastEventList = allEventList
      .where(
        (event) => ref.watch(eventTypeProvider(event)) == EventFilters.past,
      )
      .toList();
  return sortEventListDscTime(allPastEventList);
});

//MY PAST EVENTS
final myPastEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
  List<ffi.CalendarEvent> allPastEventList =
      await ref.watch(allPastEventListProvider(spaceId).future);
  List<ffi.CalendarEvent> myPastEventList = [];
  for (final event in allPastEventList) {
    final myRsvpStatus = await ref
        .watch(myRsvpStatusProvider(event.eventId().toString()).future);
    if (myRsvpStatus == ffi.RsvpStatusTag.Yes) {
      myPastEventList.add(event);
    }
  }
  return myPastEventList;
});

//EVENT FILTERS
enum EventFilters {
  all,
  bookmarked,
  ongoing,
  upcoming,
  past,
}

final eventFilterProvider =
    StateProvider.autoDispose<EventFilters>((ref) => EventFilters.all);

//SEARCH EVENTS
typedef EventListSearchParams = ({String? spaceId, String searchText});

final eventListSearchFilterProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, EventListSearchParams>(
        (ref, params) async {
  //Declare filtered event list
  List<ffi.CalendarEvent> filteredEventList = [];

  //Filter events based on the selection
  EventFilters eventFilter = ref.watch(eventFilterProvider);
  switch (eventFilter) {
    case EventFilters.bookmarked:
      {
        List<ffi.CalendarEvent> bookmarkedEventList =
            await ref.watch(bookmarkedEventListProvider(params.spaceId).future);
        filteredEventList = bookmarkedEventList;
      }
    case EventFilters.ongoing:
      {
        List<ffi.CalendarEvent> ongoingEventList =
            await ref.watch(allOngoingEventListProvider(params.spaceId).future);
        filteredEventList = ongoingEventList;
      }
    case EventFilters.upcoming:
      {
        List<ffi.CalendarEvent> upcomingEventList = await ref
            .watch(allUpcomingEventListProvider(params.spaceId).future);
        filteredEventList = upcomingEventList;
      }
    case EventFilters.past:
      {
        List<ffi.CalendarEvent> pastEventList =
            await ref.watch(allPastEventListProvider(params.spaceId).future);
        filteredEventList = pastEventList;
      }
    default:
      {
        //Get all events
        List<ffi.CalendarEvent> ongoingEventList =
            await ref.watch(allOngoingEventListProvider(params.spaceId).future);
        List<ffi.CalendarEvent> upcomingEventList = await ref
            .watch(allUpcomingEventListProvider(params.spaceId).future);
        List<ffi.CalendarEvent> pastEventList =
            await ref.watch(allPastEventListProvider(params.spaceId).future);

        //Set all events
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
