import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/actions/sort_event_list.dart';
import 'package:acter/features/events/providers/notifiers/event_notifiers.dart';
import 'package:acter/features/events/providers/notifiers/participants_notifier.dart';
import 'package:acter/features/events/providers/notifiers/rsvp_notifier.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
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

//MY RSVP STATUS PROVIDER
final participantsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncParticipantsNotifier, List<String>, String>(
      () => AsyncParticipantsNotifier(),
    );

//SpaceId == null : GET LIST OF ALL PINs
//SpaceId != null : GET LIST OF SPACE PINs
final _allEventListProvider = AsyncNotifierProvider.family<
  EventListNotifier,
  List<ffi.CalendarEvent>,
  String?
>(() => EventListNotifier());

final allEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>(
      (ref, spaceId) async => sortEventListDscTime(
        await ref.watch(_allEventListProvider(spaceId).future),
      ),
    );

final isEmptyEventList = FutureProvider.autoDispose.family<bool, String?>((
  ref,
  spaceId,
) async {
  final allEvents = await ref.watch(_allEventListProvider(spaceId).future);
  return allEvents.isEmpty;
});

final allEventSorted = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>(
      (ref, spaceId) async =>
          (await ref.watch(allOngoingEventListProvider(spaceId).future))
              .followedBy(
                await ref.watch(allUpcomingEventListProvider(spaceId).future),
              )
              .followedBy(
                await ref.watch(allPastEventListProvider(spaceId).future),
              )
              .toList(),
    );

//ALL ONGOING EVENTS
final bookmarkedEventListProvider = FutureProvider.autoDispose.family<
  List<ffi.CalendarEvent>,
  String?
>((ref, spaceId) async {
  final allEventList = await ref.watch(allEventListProvider(spaceId).future);
  final bookmarkedEventIds =
      ref.watch(bookmarkByTypeProvider(BookmarkType.events)).valueOrNull ?? [];
  List<ffi.CalendarEvent> bookmarkedEventList =
      allEventList.where((event) {
        return bookmarkedEventIds.contains(event.eventId().toString());
      }).toList();
  return sortEventListAscTime(bookmarkedEventList);
});

//ALL ONGOING EVENTS
final allOngoingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
      final allEventList = await ref.watch(
        allEventListProvider(spaceId).future,
      );
      List<ffi.CalendarEvent> allOngoingEventList =
          allEventList
              .where(
                (event) =>
                    ref.watch(eventTypeProvider(event)) == EventFilters.ongoing,
              )
              .toList();
      return sortEventListAscTime(allOngoingEventList);
    });

//ALL ONGOING EVENTS
final allOngoingEventListWithSearchProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
      final allEventList = await ref.watch(
        allOngoingEventListProvider(spaceId).future,
      );
      final searchTerm = ref.watch(eventListSearchTermProvider(spaceId));
      final eventList = _filterEventBySearchTerm(searchTerm, allEventList);
      return sortEventListAscTime(eventList);
    });

//MY ONGOING EVENTS
final myOngoingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
      List<ffi.CalendarEvent> allOngoingEventList = await ref.watch(
        allOngoingEventListProvider(spaceId).future,
      );
      List<ffi.CalendarEvent> myOngoingEventList = [];
      for (final event in allOngoingEventList) {
        final myRsvpStatus = await ref.watch(
          myRsvpStatusProvider(event.eventId().toString()).future,
        );
        if (myRsvpStatus == ffi.RsvpStatusTag.Yes) {
          myOngoingEventList.add(event);
        }
      }
      return myOngoingEventList;
    });

//ALL UPCOMING EVENTS
final allUpcomingEventListProvider = FutureProvider.autoDispose.family<
  List<ffi.CalendarEvent>,
  String?
>((ref, spaceId) async {
  final allEventList = await ref.watch(allEventListProvider(spaceId).future);
  List<ffi.CalendarEvent> allUpcomingEventList =
      allEventList
          .where(
            (event) =>
                ref.watch(eventTypeProvider(event)) == EventFilters.upcoming,
          )
          .toList();
  return sortEventListAscTime(allUpcomingEventList);
});

//ALL UPCOMING EVENTS
final allUpcomingEventListWithSearchProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
      final allEventList = await ref.watch(
        allUpcomingEventListProvider(spaceId).future,
      );
      final searchTerm = ref.watch(eventListSearchTermProvider(spaceId));
      final eventList = _filterEventBySearchTerm(searchTerm, allEventList);
      return sortEventListAscTime(eventList);
    });

//MY UPCOMING EVENTS
final myUpcomingEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
      List<ffi.CalendarEvent> allUpcomingEventList = await ref.watch(
        allUpcomingEventListProvider(spaceId).future,
      );
      List<ffi.CalendarEvent> myUpcomingEventList = [];
      for (final event in allUpcomingEventList) {
        final myRsvpStatus = await ref.watch(
          myRsvpStatusProvider(event.eventId().toString()).future,
        );
        if (myRsvpStatus == ffi.RsvpStatusTag.Yes) {
          myUpcomingEventList.add(event);
        }
      }
      return myUpcomingEventList;
    });

//ALL PAST EVENTS
final allPastEventListProvider = FutureProvider.autoDispose.family<
  List<ffi.CalendarEvent>,
  String?
>((ref, spaceId) async {
  final allEventList = await ref.watch(allEventListProvider(spaceId).future);
  List<ffi.CalendarEvent> allPastEventList =
      allEventList
          .where(
            (event) => ref.watch(eventTypeProvider(event)) == EventFilters.past,
          )
          .toList();
  return sortEventListDscTime(allPastEventList);
});

//ALL PAST EVENTS
final allPastEventListWithSearchProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
      final allEventList = await ref.watch(
        allPastEventListProvider(spaceId).future,
      );
      final searchTerm = ref.watch(eventListSearchTermProvider(spaceId));
      final eventList = _filterEventBySearchTerm(searchTerm, allEventList);
      return sortEventListDscTime(eventList);
    });

//MY PAST EVENTS
final myPastEventListProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
      List<ffi.CalendarEvent> allPastEventList = await ref.watch(
        allPastEventListProvider(spaceId).future,
      );
      List<ffi.CalendarEvent> myPastEventList = [];
      for (final event in allPastEventList) {
        final myRsvpStatus = await ref.watch(
          myRsvpStatusProvider(event.eventId().toString()).future,
        );
        if (myRsvpStatus == ffi.RsvpStatusTag.Yes) {
          myPastEventList.add(event);
        }
      }
      return myPastEventList;
    });

//EVENT FILTERS
enum EventFilters { all, bookmarked, ongoing, upcoming, past }

//SEARCH EVENTS
typedef EventListSearchParams =
    ({String? spaceId, String searchText, EventFilters eventFilter});

List<ffi.CalendarEvent> _filterEventBySearchTerm(
  String term,
  List<ffi.CalendarEvent> events,
) {
  final cleanedTerm = term.trim().toLowerCase();
  if (cleanedTerm.isEmpty) {
    return events;
  }

  return events
      .where((e) => e.title().toLowerCase().contains(cleanedTerm))
      .toList();
}

final eventListSearchTermProvider = StateProvider.family<String, String?>(
  (ref, spaceId) => '',
);

final eventListFilterProvider = StateProvider.family<EventFilters, String?>(
  (ref, spaceId) => EventFilters.all,
);

final eventListSearchedProvider = FutureProvider.autoDispose
    .family<List<ffi.CalendarEvent>, String?>((ref, spaceId) async {
      final searchTerm = ref.watch(eventListSearchTermProvider(spaceId));
      return _filterEventBySearchTerm(
        searchTerm,
        await ref.watch(allEventListProvider(spaceId).future),
      );
    });

final eventListQuickSearchedProvider =
    FutureProvider.autoDispose<List<ffi.CalendarEvent>>((ref) async {
      final searchTerm = ref.watch(quickSearchValueProvider);

      // Fetch the full list of events
      final allEventList = await ref.watch(allEventSorted(null).future);

      return _filterEventBySearchTerm(searchTerm, allEventList);
    });