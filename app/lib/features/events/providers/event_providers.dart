import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final spaceEventsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncSpaceEventsNotifier, List<ffi.CalendarEvent>, String>(
  () => AsyncSpaceEventsNotifier(),
);

class AsyncSpaceEventsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ffi.CalendarEvent>, String> {
  late Stream<bool> _listener;

  Future<List<ffi.CalendarEvent>> _getEvents(ffi.Space arg) async {
    return (await arg.calendarEvents()).toList(); // this might throw internally
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
    return (await client.allUpcomingEvents(null)).toList();
    // this might throw internally
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
    return (await client.myUpcomingEvents(null)).toList();
    // this might throw internally
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
    return (await client.myPastEvents(null)).toList();
    // this might throw internally
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

final myRsvpStatusProvider = FutureProvider.family
    .autoDispose<ffi.OptionRsvpStatus, String>((ref, calendarId) async {
  final event = await ref.watch(calendarEventProvider(calendarId).future);
  return await event.respondedByMe();
});
