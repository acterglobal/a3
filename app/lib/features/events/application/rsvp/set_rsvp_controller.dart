import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetRsvpController extends StateNotifier<AsyncValue<String?>> {
  final String calendarId;
  final EventRepositoryInterface _repository;
  SetRsvpController(this._repository, this.calendarId)
      : super(const AsyncData(null));

  Future<void> setRsvp(String status) async {
    EasyLoading.show(status: 'Updating RSVP status', dismissOnTap: false);
    final calendarEvent = await _repository.setRsvpForEvent(calendarId, status);
    state = calendarEvent.fold(
      (l) {
        EasyLoading.dismiss();
        return AsyncError(l, StackTrace.current);
      },
      (r) {
        EasyLoading.dismiss();
        return AsyncData(r);
      },
    );
  }
}
