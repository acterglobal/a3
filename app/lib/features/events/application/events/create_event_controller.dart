import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateEventController
    extends StateNotifier<AsyncValue<ffi.CalendarEvent?>> {
  final EventRepositoryInterface _repository;
  CreateEventController(this._repository) : super(const AsyncValue.data(null));

  /// Create Calendar event.
  Future<void> create(
    String spaceId,
    String title,
    String? description,
    String startTime,
    String endTime,
  ) async {
    EasyLoading.show(status: 'Creating event', dismissOnTap: false);
    state = const AsyncValue.loading();
    final calendarEvent = await _repository.createCalendarEvent(
      spaceId,
      title,
      description,
      startTime,
      endTime,
    );

    state = calendarEvent.fold(
      (l) {
        EasyLoading.showError('Error creating event: $l');
        return AsyncError(l.toString(), StackTrace.current);
      },
      (r) {
        EasyLoading.dismiss();
        return AsyncValue<ffi.CalendarEvent>.data(r);
      },
    );
  }
}
