import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

class EventListNotifier
    extends FamilyAsyncNotifier<List<ffi.CalendarEvent>, String?> {
  late Stream<bool> _listener;

  Future<List<ffi.CalendarEvent>> _getEventList(ffi.Client client) async {
    final spaceId = arg;
    //GET ALL EVENTS
    if (spaceId == null) {
      return (await client.calendarEvents()).toList();
    } else {
      //GET SPACE EVENTS
      final space = await client.space(spaceId);
      return (await space.calendarEvents()).toList();
    }
  }

  @override
  Future<List<ffi.CalendarEvent>> build(String? arg) async {
    final client = ref.watch(alwaysClientProvider);

    //GET ALL EVENTS
    if (arg == null) {
      _listener =
          client.subscribeStream('calendar'); // keep it resident in memory
    } else {
      //GET SPACE EVENTS
      _listener = client.subscribeStream('$arg::calendar');
    }

    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getEventList(client));
    });
    return await _getEventList(client);
  }
}

class AsyncCalendarEventNotifier
    extends AutoDisposeFamilyAsyncNotifier<ffi.CalendarEvent, String> {
  late Stream<bool> _listener;

  Future<ffi.CalendarEvent> _getCalendarEvent(ffi.Client client) async {
    return await client.waitForCalendarEvent(arg, null);
  }

  @override
  Future<ffi.CalendarEvent> build(String arg) async {
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(arg); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(() => _getCalendarEvent(client));
    });
    return await _getCalendarEvent(client);
  }
}
