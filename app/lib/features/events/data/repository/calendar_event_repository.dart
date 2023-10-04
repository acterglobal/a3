import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter/material.dart';

abstract class CalendarEventRepository {
  /// all events
  Future<List<ffi.CalendarEvent>> getCalendarEvents();
  Future<List<ffi.CalendarEvent>> getUpcomingCalendarEvents();
  Future<List<ffi.CalendarEvent>> getPastCalendarEvents();
  Future<ffi.CalendarEvent> getCalendarEvent(String eventId);

  /// space events
  Future<List<ffi.CalendarEvent>> getSpaceCalendarEvents(String spaceId);
}

class CalendarRepositoryImpl implements CalendarEventRepository {
  final ffi.Client client;
  late Stream<void> _listener;
  CalendarRepositoryImpl(this.client);

  @override
  Future<List<ffi.CalendarEvent>> getCalendarEvents() async {
    // FIXME: how to get informed about updates ?!?!
    final calendarEvents = await client.calendarEvents();
    return calendarEvents.toList();
  }

  @override
  Future<List<ffi.CalendarEvent>> getUpcomingCalendarEvents() async {
    // FIXME: how to get informed about updates ?!?!
    final calendarEvents =
        await client.myUpcomingEvents(DateTime.now().millisecondsSinceEpoch);
    return calendarEvents.toList();
  }

  @override
  Future<List<ffi.CalendarEvent>> getPastCalendarEvents() async {
    // FIXME: how to get informed about updates ?!?!
    final calendarEvents =
        await client.myPastEvents(DateTime.now().millisecondsSinceEpoch);
    return calendarEvents.toList();
  }

  @override
  Future<List<ffi.CalendarEvent>> getSpaceCalendarEvents(
    String spaceId,
  ) async {
    try {
      final space = await client.space(spaceId);
      _listener = client.subscribeStream('$spaceId::calendar');
      return await _listener
          .map((e) async => (await space.calendarEvents()).toList())
          .first;
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      rethrow;
    }
  }

  @override
  Future<ffi.CalendarEvent> getCalendarEvent(String eventId) async {
    _listener = client.subscribeStream(eventId);
    return await _listener.map((e) async {
      try {
        return await client.calendarEvent(eventId);
      } catch (e) {
        return await client.waitForCalendarEvent(eventId, null);
      }
    }).first;
  }
}
