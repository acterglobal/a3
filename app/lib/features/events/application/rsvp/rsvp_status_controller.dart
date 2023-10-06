import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RsvpStatusController extends StateNotifier<AsyncValue<String>> {
  final String calendarId;
  final EventRepositoryInterface _repository;
  RsvpStatusController(this._repository, this.calendarId)
      : super(const AsyncLoading()) {
    _get();
  }

  void _get() async {
    final calendarEvent = await _repository.getMyRsvpStatus(calendarId);
    state = calendarEvent.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
