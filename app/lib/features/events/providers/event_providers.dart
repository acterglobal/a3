import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;

final spaceEventsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncSpaceEventsNotifier, List<ffi.CalendarEvent>, String>(
  () => AsyncSpaceEventsNotifier(),
);

class AsyncSpaceEventsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ffi.CalendarEvent>, String> {
  late Stream<void> _listener;
  Future<List<ffi.CalendarEvent>> _getEvents(ffi.Space arg) async {
    return (await arg.calendarEvents()).toList(); // this might throw internally
  }

  @override
  Future<List<ffi.CalendarEvent>> build(String arg) async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    final space = await client.space(arg);
    _listener = client.subscribeStream('$arg::calendar'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getEvents(space));
    });
    return _getEvents(space);
  }
}

final calendarEventProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncCalendarEventNotifier, ffi.CalendarEvent, String>(
  () => AsyncCalendarEventNotifier(),
);

class AsyncCalendarEventNotifier
    extends AutoDisposeFamilyAsyncNotifier<ffi.CalendarEvent, String> {
  late Stream<void> _listener;
  Future<ffi.CalendarEvent> _getCalendarEvent() async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    try {
      return await client.calendarEvent(arg);
    } catch (e) {
      return await client.waitForCalendarEvent(arg, null);
    }
    // this might throw internally
  }

  @override
  Future<ffi.CalendarEvent> build(String arg) async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    _listener = client.subscribeStream(arg); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getCalendarEvent());
    });
    return _getCalendarEvent();
  }
}

final allUpcomingEventsProvider = AsyncNotifierProvider.autoDispose<
    AsyncUpcomingEventsNotifier,
    List<ffi.CalendarEvent>>(() => AsyncUpcomingEventsNotifier());

class AsyncUpcomingEventsNotifier
    extends AutoDisposeAsyncNotifier<List<ffi.CalendarEvent>> {
  late Stream<void> _listener;
  Future<List<ffi.CalendarEvent>> _getAllUpcoming() async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    return (await client.allUpcomingEvents(null)).toList();
    // this might throw internally
  }

  @override
  Future<List<ffi.CalendarEvent>> build() async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    _listener = client.subscribeStream('calendar'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getAllUpcoming());
    });
    return _getAllUpcoming();
  }
}

final myUpcomingEventsProvider = AsyncNotifierProvider.autoDispose<
    AsyncMyUpcomingEventsNotifier,
    List<ffi.CalendarEvent>>(() => AsyncMyUpcomingEventsNotifier());

class AsyncMyUpcomingEventsNotifier
    extends AutoDisposeAsyncNotifier<List<ffi.CalendarEvent>> {
  late Stream<void> _listener;
  Future<List<ffi.CalendarEvent>> _getMyUpcoming() async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    return (await client.myUpcomingEvents(null)).toList();
    // this might throw internally
  }

  @override
  Future<List<ffi.CalendarEvent>> build() async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    _listener = client.subscribeStream('calendar'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getMyUpcoming());
    });
    return _getMyUpcoming();
  }
}

final myPastEventsProvider = AsyncNotifierProvider.autoDispose<
    AsyncMyPastEventsNotifier,
    List<ffi.CalendarEvent>>(() => AsyncMyPastEventsNotifier());

class AsyncMyPastEventsNotifier
    extends AutoDisposeAsyncNotifier<List<ffi.CalendarEvent>> {
  late Stream<void> _listener;
  Future<List<ffi.CalendarEvent>> _getMyPast() async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    return (await client.myPastEvents(null)).toList();
    // this might throw internally
  }

  @override
  Future<List<ffi.CalendarEvent>> build() async {
    final client = ref.watch(clientProvider);
    if (client == null) throw UnimplementedError('Client is not available');
    _listener = client.subscribeStream('calendar'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getMyPast());
    });
    return _getMyPast();
  }
}

final myRsvpStatusProvider =
    FutureProvider.family.autoDispose<String, String>((ref, calendarId) async {
  final event = await ref.watch(calendarEventProvider(calendarId).future);
  return (await event.myRsvpStatus());
});
