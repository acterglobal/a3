import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RsvpEntriesController extends StateNotifier<AsyncValue<List<ffi.Rsvp>?>> {
  final String calendarId;
  final EventRepositoryInterface _repository;
  RsvpEntriesController(this._repository, this.calendarId)
      : super(const AsyncData(null));

  Future<void> rsvpEntries(String status) async {
    final calendarEvent = await _repository.getRsvpEntries(calendarId);
    state = calendarEvent.fold(
      (l) => AsyncError(l, StackTrace.current),
      (r) => AsyncData(r),
    );
  }
}
