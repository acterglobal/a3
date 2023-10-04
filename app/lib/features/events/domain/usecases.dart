import 'package:acter/features/events/data/repository/calendar_event_repository.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;

class GetCalendarEventsUseCase {
  final CalendarEventRepository _repository;

  GetCalendarEventsUseCase(this._repository);

  Future<List<ffi.CalendarEvent>> execute() {
    return _repository.getCalendarEvents();
  }
}

class GetCalendarEventUseCase {
  final CalendarEventRepository _repository;

  GetCalendarEventUseCase(this._repository);

  Future<ffi.CalendarEvent> execute(String eventId) {
    return _repository.getCalendarEvent(eventId);
  }
}

class GetUpcomingCalendarEventsUseCase {
  final CalendarEventRepository _repository;

  GetUpcomingCalendarEventsUseCase(this._repository);

  Future<List<ffi.CalendarEvent>> execute() {
    return _repository.getUpcomingCalendarEvents();
  }
}

class GetPastCalendarEventsUseCase {
  final CalendarEventRepository _repository;

  GetPastCalendarEventsUseCase(this._repository);

  Future<List<ffi.CalendarEvent>> execute() {
    return _repository.getPastCalendarEvents();
  }
}

class GetSpaceCalendarEventsUseCase {
  final CalendarEventRepository _repository;

  GetSpaceCalendarEventsUseCase(this._repository);

  Future<List<ffi.CalendarEvent>> execute(String spaceId) {
    return _repository.getSpaceCalendarEvents(spaceId);
  }
}
