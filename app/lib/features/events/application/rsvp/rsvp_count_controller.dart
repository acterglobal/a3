import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RsvpCountController extends StateNotifier<AsyncValue<int>> {
  final String calendarId;
  final EventRepositoryInterface _repository;
  RsvpCountController(this._repository, this.calendarId)
      : super(const AsyncLoading()) {
    _get();
  }

  void _get() async {
    final calendarEvent = await _repository.getRsvpCount(calendarId);
    state = calendarEvent.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
