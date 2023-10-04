import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceEventsListController
    extends StateNotifier<AsyncValue<List<ffi.CalendarEvent>>> {
  final String spaceId;
  final EventRepositoryInterface _repository;
  SpaceEventsListController(this._repository, this.spaceId)
      : super(const AsyncLoading()) {
    _get();
  }

  void _get() async {
    final spaceEvents = await _repository.getSpaceCalendarEvents(spaceId);
    state = spaceEvents.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
