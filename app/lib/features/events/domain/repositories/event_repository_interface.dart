import 'package:acter/features/events/domain/failures/failure.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:fpdart/fpdart.dart';

/// Calendar Events repository interface
abstract class EventRepositoryInterface {
  /// Get all calendar events
  Future<Either<Failure, List<ffi.CalendarEvent>>> getCalendarEvents();

  /// Get calendar events by id
  Future<Either<Failure, ffi.CalendarEvent>> getCalendarEvent(
    String calendarId,
  );

  /// Get space calendar events
  Future<Either<Failure, List<ffi.CalendarEvent>>> getSpaceCalendarEvents(
    String spaceId,
  );

  /// Get upcoming events in response to RSVPs
  Future<Either<Failure, List<ffi.CalendarEvent>>> getUpcomingEvents();

  /// Get past events in response to RSVPs
  Future<Either<Failure, List<ffi.CalendarEvent>>> getPastEvents();

  /// Create calendar event
  Future<Either<Failure, ffi.CalendarEvent>> createCalendarEvent(
    String spaceId,
    String title,
    String? description,
    String startTime,
    String endTime,
  );

  /// Update calendar event
  Future<Either<Failure, ffi.CalendarEvent>> editCalendarEvent(
    String spaceId,
    String calendarId,
    String title,
    String? description,
    String startTime,
    String endTime,
  );

  /// Redact calendar event
  Future<Either<Failure, bool>> redactCalendarEvent(
    String spaceId,
    String eventId,
    String? reason,
  );

  /// Set Rsvp of calendar event
  Future<Either<Failure, String>> setRsvpForEvent(
    String calendarId,
    String status,
  );

  /// get Rsvp responders of calendar event
  Future<Either<Failure, List<ffi.Rsvp>>> getRsvpEntries(
    String calendarId,
  );

  /// get user Rsvp status of calendar event
  Future<Either<Failure, String>> getMyRsvpStatus(String calendarId);

  /// get total rsvp responders count of calendar event
  Future<Either<Failure, int>> getRsvpCount(String calendarId);

  Future<Either<Failure, int>> getRsvpCountAtStatus(
    String calendarId,
    String status,
  );

  Future<Either<Failure, List<String>>> getUsersAtStatus(
    String calendarId,
    String status,
  );

  Future<void> onDisposeSub();
}
