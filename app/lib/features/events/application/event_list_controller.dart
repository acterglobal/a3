import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarEventListController
    extends StateNotifier<AsyncValue<List<ffi.CalendarEvent>>> {
  final EventRepositoryInterface _repository;
  CalendarEventListController(this._repository) : super(const AsyncLoading()) {
    _get();
  }

  void _get() async {
    final events = await _repository.getCalendarEvents();
    state = events.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
