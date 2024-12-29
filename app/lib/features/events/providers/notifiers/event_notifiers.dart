import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show CalendarEvent, Client;
import 'package:riverpod/riverpod.dart';

class EventListNotifier
    extends FamilyAsyncNotifier<List<CalendarEvent>, String?> {
  late Stream<bool> _listener;

  Future<List<CalendarEvent>> _getEventList(
    Client client,
    String? spaceId,
  ) async {
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
  Future<List<CalendarEvent>> build(String? arg) async {
    final spaceId = arg;
    final client = ref.watch(alwaysClientProvider);

    //GET ALL EVENTS
    if (spaceId == null) {
      _listener =
          client.subscribeStream('calendar'); // keep it resident in memory
    } else {
      //GET SPACE EVENTS
      _listener = client.subscribeStream('$spaceId::calendar');
    }

    _listener.forEach((e) async {
      state = AsyncValue.data(await _getEventList(client, spaceId));
    });
    return await _getEventList(client, spaceId);
  }
}

class AsyncCalendarEventNotifier
    extends AutoDisposeFamilyAsyncNotifier<CalendarEvent, String> {
  late Stream<bool> _listener;

  Future<CalendarEvent> _getCalEvent(Client client, String calEvtId) async {
    return await client.waitForCalendarEvent(calEvtId, null);
  }

  @override
  Future<CalendarEvent> build(String arg) async {
    final calEvtId = arg;
    final client = ref.watch(alwaysClientProvider);
    _listener = client.subscribeStream(calEvtId); // keep it resident in memory
    _listener.forEach((e) async {
      state = AsyncData(await _getCalEvent(client, calEvtId));
    });
    return await _getCalEvent(client, calEvtId);
  }
}
