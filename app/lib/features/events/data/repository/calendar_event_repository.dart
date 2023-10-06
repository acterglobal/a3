import 'dart:async';

import 'package:acter/features/events/domain/failures/failure.dart';
import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

class CalendarEventRepository implements EventRepositoryInterface {
  final ffi.Client client;
  late Stream<bool> _listener;
  late StreamSubscription<bool> _sub;
  CalendarEventRepository(this.client);

  @override
  Future<Either<Failure, List<ffi.CalendarEvent>>> getCalendarEvents() async {
    // FIXME: how to get informed about updates ?!?!
    final calendarEvents = await client.calendarEvents();
    return right(calendarEvents.toList());
  }

  @override
  Future<Either<Failure, List<ffi.CalendarEvent>>> getUpcomingEvents() async {
    // FIXME: how to get informed about updates ?!?!
    final calendarEvents = await client.myUpcomingEvents(null);
    return right(calendarEvents.toList());
  }

  @override
  Future<Either<Failure, List<ffi.CalendarEvent>>> getPastEvents() async {
    // FIXME: how to get informed about updates ?!?!
    final calendarEvents = await client.myPastEvents(null);
    return right(calendarEvents.toList());
  }

  @override
  Future<Either<Failure, List<ffi.CalendarEvent>>> getSpaceCalendarEvents(
    String spaceId,
  ) async {
    _listener = client.subscribeStream('$spaceId::calendar');

    try {
      final space = await client.space(spaceId);
      List<ffi.CalendarEvent> events = (await space.calendarEvents()).toList();
      _sub = _listener.listen(
        (e) async {
          debugPrint('seen event update on space $spaceId');
          events = (await space.calendarEvents()).toList();
        },
        onError: (e, stack) {
          debugPrint('stream errored: $e : $stack');
        },
        onDone: () {
          debugPrint('stream ended');
        },
      );
      return right(events);
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      rethrow;
    }
  }

  @override
  Future<Either<Failure, ffi.CalendarEvent>> getCalendarEvent(
    String eventId,
  ) async {
    _listener = client.subscribeStream(eventId);

    try {
      ffi.CalendarEvent event = await client.calendarEvent(eventId);
      _sub = _listener.listen(
        (e) async {
          debugPrint('seen event update on id $eventId');
          event = await client.calendarEvent(eventId);
        },
        onError: (e, stack) async {
          event = await client.waitForCalendarEvent(eventId, null);
          debugPrint('stream errored: $e : $stack');
        },
        onDone: () {
          debugPrint('stream ended');
        },
      );
      return right(event);
    } catch (e) {
      debugPrint('Error fetching calendar event: $e');
      rethrow;
    }
  }

  @override
  Future<Either<Failure, ffi.CalendarEvent>> createCalendarEvent(
    String spaceId,
    String title,
    String? description,
    String startTime,
    String endTime,
  ) async {
    final space = await client.space(spaceId);
    final draft = space.calendarEventDraft();
    draft.title(title);
    draft.descriptionText(description ?? '');
    draft.utcStartFromRfc3339(startTime);
    draft.utcEndFromRfc3339(endTime);
    final eventId = await draft.send();
    final calendarEvent =
        await client.waitForCalendarEvent(eventId.toString(), null);

    /// Event is created, set RSVP status to `Yes` by default for host.
    final rsvpManager = await calendarEvent.rsvpManager();
    final rsvpDraft = rsvpManager.rsvpDraft();
    rsvpDraft.status('Yes');
    await rsvpDraft.send();
    debugPrint('Created Calendar Event: ${eventId.toString()}');
    return right(calendarEvent);
  }

  @override
  Future<Either<Failure, ffi.CalendarEvent>> editCalendarEvent(
    String spaceId,
    String calendarId,
    String title,
    String? description,
    String startTime,
    String endTime,
  ) async {
    final calendarEvent = await client.calendarEvent(calendarId);
    final eventUpdateBuilder = calendarEvent.updateBuilder();
    eventUpdateBuilder.title(title);
    eventUpdateBuilder.descriptionText(description ?? '');
    eventUpdateBuilder.utcStartFromRfc3339(startTime);
    eventUpdateBuilder.utcEndFromRfc3339(endTime);

    final eventId = await eventUpdateBuilder.send();
    debugPrint('Calendar Event updated: $eventId');
    await client.waitForCalendarEvent(calendarId, null);

    return right(calendarEvent);
  }

  @override
  Future<Either<Failure, bool>> redactCalendarEvent(
    String spaceId,
    String eventId,
    String? reason,
  ) async {
    final space = await client.space(spaceId);
    final calendarEvent = await client.calendarEvent(eventId);
    final user = calendarEvent.sender().toString();
    final res = await space.redactContent(eventId, reason);
    debugPrint('Content from user:{$user flagged $res reason:$reason}');
    return right(res);
  }

  @override
  Future<Either<Failure, String>> setRsvpForEvent(
    String calendarId,
    String status,
  ) async {
    final event = await client.calendarEvent(calendarId);
    final rsvpManager = await event.rsvpManager();
    final draft = rsvpManager.rsvpDraft();
    draft.status(status);
    final res = await draft.send();
    return right(res.toString());
  }

  @override
  Future<Either<Failure, List<ffi.Rsvp>>> getRsvpEntries(
    String calendarId,
  ) async {
    final event = await client.calendarEvent(calendarId);
    final rsvpManager = await event.rsvpManager();
    final entries =
        await rsvpManager.rsvpEntries().then((ffiList) => ffiList.toList());
    return right(entries);
  }

  @override
  Future<Either<Failure, String>> getMyRsvpStatus(String calendarId) async {
    final event = await client.calendarEvent(calendarId);
    final rsvpManager = await event.rsvpManager();
    final status = await rsvpManager.myStatus();
    return right(status);
  }

  @override
  Future<Either<Failure, int>> getRsvpCount(String calendarId) async {
    final event = await client.calendarEvent(calendarId);
    final rsvpManager = await event.rsvpManager();
    final rsvpCount = rsvpManager.totalRsvpCount();
    return right(rsvpCount);
  }

  @override
  Future<Either<Failure, int>> getRsvpCountAtStatus(
    String calendarId,
    String status,
  ) async {
    final event = await client.calendarEvent(calendarId);
    final rsvpManager = await event.rsvpManager();
    final count = await rsvpManager.countAtStatus(status);
    return right(count);
  }

  @override
  Future<Either<Failure, List<String>>> getUsersAtStatus(
    String calendarId,
    String status,
  ) async {
    final event = await client.calendarEvent(calendarId);
    final rsvpManager = await event.rsvpManager();
    final userIds = await rsvpManager
        .usersAtStatus(status)
        .then((ffiList) => ffiList.toList());
    final userList = userIds.map((e) => e.toString()).toList();
    return right(userList);
  }

  @override
  Future<void> onDisposeSub() async {
    debugPrint('disposing events sub');
    _sub.cancel();
  }
}
