import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PastEventsListController
    extends StateNotifier<AsyncValue<List<ffi.CalendarEvent>>> {
  final EventRepositoryInterface _repository;
  PastEventsListController(this._repository) : super(const AsyncLoading()) {
    _get();
  }

  void _get() async {
    final pastEvents = await _repository.getPastEvents();
    state = pastEvents.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
