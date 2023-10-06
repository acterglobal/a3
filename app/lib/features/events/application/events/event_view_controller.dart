import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarEventViewController
    extends StateNotifier<AsyncValue<ffi.CalendarEvent>> {
  final String calendarId;
  final EventRepositoryInterface _repository;
  CalendarEventViewController(this._repository, this.calendarId)
      : super(const AsyncLoading()) {
    _get();
  }

  void _get() async {
    final calendarEvent = await _repository.getCalendarEvent(calendarId);
    state = calendarEvent.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
