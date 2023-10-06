import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditEventController
    extends StateNotifier<AsyncValue<ffi.CalendarEvent?>> {
  final EventRepositoryInterface _repository;
  EditEventController(this._repository) : super(const AsyncValue.data(null));

  /// Update Calendar event.
  Future<void> update(
    String spaceId,
    String calendarId,
    String title,
    String? description,
    String startTime,
    String endTime,
  ) async {
    EasyLoading.show(status: 'Updating Calendar Event', dismissOnTap: false);
    state = const AsyncValue.loading();
    final calendarEvent = await _repository.editCalendarEvent(
      spaceId,
      calendarId,
      title,
      description,
      startTime,
      endTime,
    );
    state = calendarEvent.fold(
      (l) {
        EasyLoading.showError('Error Updating Calendar Event: $l');
        return AsyncError(l, StackTrace.current);
      },
      (r) {
        EasyLoading.dismiss();
        return AsyncData(r);
      },
    );
  }
}
