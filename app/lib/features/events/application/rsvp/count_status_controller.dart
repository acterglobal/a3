import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CountStatusController extends StateNotifier<AsyncValue<int?>> {
  final String calendarId;
  final EventRepositoryInterface _repository;
  CountStatusController(this._repository, this.calendarId)
      : super(const AsyncData(null));

  void countAtStatus(String status) async {
    final calendarEvent =
        await _repository.getRsvpCountAtStatus(calendarId, status);
    state = calendarEvent.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
