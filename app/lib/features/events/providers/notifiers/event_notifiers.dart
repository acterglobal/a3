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
    final client = await ref.watch(alwaysClientProvider.future);

    //GET ALL EVENTS
    if (spaceId == null) {
      _listener = client
          .subscribeSectionStream('calendar'); // keep it resident in memory
    } else {
      //GET SPACE EVENTS
      _listener = client.subscribeRoomSectionStream(spaceId, 'calendar');
    }

    _listener.forEach((e) async {
      state = await AsyncValue.guard(
        () async => await _getEventList(client, spaceId),
      );
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
    final client = await ref.watch(alwaysClientProvider.future);
    _listener =
        client.subscribeModelStream(calEvtId); // keep it resident in memory
    _listener.forEach((e) async {
      state = await AsyncValue.guard(
        () async => await _getCalEvent(client, calEvtId),
      );
    });
    return await _getCalEvent(client, calEvtId);
  }
}
