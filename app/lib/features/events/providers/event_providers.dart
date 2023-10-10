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

final allUpcomingEventsProvider =
    FutureProvider.autoDispose<List<ffi.CalendarEvent>>((ref) async {
  final client = ref.watch(clientProvider);
  if (client == null) throw UnimplementedError('Client is not available');
  // FIXME: how to get informed about updates??
  return (await client.allUpcomingEvents(null)).toList();
});

final myUpcomingEventsProvider =
    FutureProvider.autoDispose<List<ffi.CalendarEvent>>((ref) async {
  final client = ref.watch(clientProvider);
  if (client == null) throw UnimplementedError('Client is not available');
  // FIXME: how to get informed about updates??
  return (await client.myUpcomingEvents(null)).toList();
});

final myPastEventsProvider =
    FutureProvider.autoDispose<List<ffi.CalendarEvent>>((ref) async {
  final client = ref.watch(clientProvider);
  if (client == null) throw UnimplementedError('Client is not available');

  // FIXME: how to get informed about updates??
  return (await client.myPastEvents(null)).toList();
});

final myRsvpStatusProvider =
    FutureProvider.family.autoDispose<String, String>((ref, calendarId) async {
  final event = await ref.watch(calendarEventProvider(calendarId).future);
  return (await event.myRsvpStatus());
});
