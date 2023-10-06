import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RsvpUsersController extends StateNotifier<AsyncValue<List<String>>> {
  final String calendarId;
  final EventRepositoryInterface _repository;
  RsvpUsersController(this._repository, this.calendarId)
      : super(const AsyncData([]));

  Future<void> rsvpCount() async {
    final users = await _repository.getUsersAtStatus(calendarId, 'Yes');
    state = users.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
