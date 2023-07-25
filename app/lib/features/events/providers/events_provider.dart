import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent, Space;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncSpaceEventsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<CalendarEvent>, Space> {
  late Stream<void> _listener;
  Future<List<CalendarEvent>> _getEvents() async {
    return (await arg.calendarEvents()).toList(); // this might throw internally
  }

  @override
  Future<List<CalendarEvent>> build(Space arg) async {
    final client = ref.watch(clientProvider)!;
    final spaceId = arg.getRoomId();
    _listener = client.subscribeStream('$spaceId::calendar'); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getEvents());
    });
    return _getEvents();
  }
}

final spaceEventsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncSpaceEventsNotifier, List<CalendarEvent>, Space>(
  () => AsyncSpaceEventsNotifier(),
);

class AsyncCalendarEventNotifier
    extends AutoDisposeFamilyAsyncNotifier<CalendarEvent, String> {
  late Stream<void> _listener;
  Future<CalendarEvent> _getCalendarEvent() async {
    final client = ref.watch(clientProvider)!;
    try {
      return await client.calendarEvent(arg);
    } catch (e) {
      return await client.waitForCalendarEvent(arg, null);
    }
    // this might throw internally
  }

  @override
  Future<CalendarEvent> build(String arg) async {
    final client = ref.watch(clientProvider)!;
    _listener = client.subscribeStream(arg); // stay up to date
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getCalendarEvent());
    });
    return _getCalendarEvent();
  }
}

final calendarEventProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncCalendarEventNotifier, CalendarEvent, String>(
  () => AsyncCalendarEventNotifier(),
);
