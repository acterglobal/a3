import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

final spaceEventsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncSpaceEventsNotifier, List<ffi.CalendarEvent>, String>(
  () => AsyncSpaceEventsNotifier(),
);

class AsyncSpaceEventsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ffi.CalendarEvent>, String> {
  late Stream<bool> _listener;

  Future<List<ffi.CalendarEvent>> _getEvents(ffi.Space space) async {
    final events = await space.calendarEvents(); // this might throw internally
    return events.toList();
  }

  @override
  Future<List<ffi.CalendarEvent>> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    final space = await client.space(arg);
    _listener =
        client.subscribeStream('$arg::calendar'); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getEvents(space));
    });
    return await _getEvents(space);
  }
}

final calendarEventProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncCalendarEventNotifier, ffi.CalendarEvent, String>(
  () => AsyncCalendarEventNotifier(),
);

class AsyncCalendarEventNotifier
    extends AutoDisposeFamilyAsyncNotifier<ffi.CalendarEvent, String> {
  late Stream<bool> _listener;

  Future<ffi.CalendarEvent> _getCalendarEvent() async {
    final client = ref.read(alwaysClientProvider);
    return await client.waitForCalendarEvent(arg, null);
  }

  @override
  Future<ffi.CalendarEvent> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(arg); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(_getCalendarEvent);
    });
    return await _getCalendarEvent();
  }
}

final allUpcomingEventsProvider = AsyncNotifierProvider.autoDispose<
    AsyncUpcomingEventsNotifier,
    List<ffi.CalendarEvent>>(() => AsyncUpcomingEventsNotifier());

class AsyncUpcomingEventsNotifier
    extends AutoDisposeAsyncNotifier<List<ffi.CalendarEvent>> {
  late Stream<bool> _listener;

  Future<List<ffi.CalendarEvent>> _getAllUpcoming() async {
    final client = ref.read(alwaysClientProvider);
    final events =
        await client.allUpcomingEvents(null); // this might throw internally
    return _sortEventListAscTime(events.toList());
  }

  @override
  Future<List<ffi.CalendarEvent>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener =
        client.subscribeStream('calendar'); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(_getAllUpcoming);
    });
    return await _getAllUpcoming();
  }
}

final myUpcomingEventsProvider = AsyncNotifierProvider.autoDispose<
    AsyncMyUpcomingEventsNotifier,
    List<ffi.CalendarEvent>>(() => AsyncMyUpcomingEventsNotifier());

class AsyncMyUpcomingEventsNotifier
    extends AutoDisposeAsyncNotifier<List<ffi.CalendarEvent>> {
  late Stream<bool> _listener;

  Future<List<ffi.CalendarEvent>> _getMyUpcoming() async {
    final client = ref.read(alwaysClientProvider);
    final events =
        await client.myUpcomingEvents(null); // this might throw internally
    return _sortEventListAscTime(events.toList());
  }

  @override
  Future<List<ffi.CalendarEvent>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener =
        client.subscribeStream('calendar'); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(_getMyUpcoming);
    });
    return await _getMyUpcoming();
  }
}

final myPastEventsProvider = AsyncNotifierProvider.autoDispose<
    AsyncMyPastEventsNotifier,
    List<ffi.CalendarEvent>>(() => AsyncMyPastEventsNotifier());

class AsyncMyPastEventsNotifier
    extends AutoDisposeAsyncNotifier<List<ffi.CalendarEvent>> {
  late Stream<bool> _listener;

  Future<List<ffi.CalendarEvent>> _getMyPast() async {
    final client = ref.read(alwaysClientProvider);
    final events =
        await client.myPastEvents(null); // this might throw internally
    return _sortEventListDscTime(events.toList());
  }

  @override
  Future<List<ffi.CalendarEvent>> build() async {
    final client = ref.watch(alwaysClientProvider);
    _listener =
        client.subscribeStream('calendar'); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(_getMyPast);
    });
    return await _getMyPast();
  }
}


Future<List<ffi.CalendarEvent>> _sortEventListAscTime(
    List<ffi.CalendarEvent> eventsList,
    ) async {
  eventsList.sort(
        (a, b) => a.utcStart().timestamp().compareTo(b.utcStart().timestamp()),
  );
  return eventsList;
}

Future<List<ffi.CalendarEvent>> _sortEventListDscTime(
    List<ffi.CalendarEvent> eventsList,
    ) async {
  eventsList.sort(
        (a, b) => b.utcStart().timestamp().compareTo(a.utcStart().timestamp()),
  );
  return eventsList;
}

final myRsvpStatusProvider = FutureProvider.family
    .autoDispose<ffi.OptionRsvpStatus, String>((ref, calendarId) async {
  final event = await ref.watch(calendarEventProvider(calendarId).future);
  return await event.respondedByMe();
});
