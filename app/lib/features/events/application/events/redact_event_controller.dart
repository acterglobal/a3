import 'package:acter/features/events/domain/repositories/event_repository_interface.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RedactEventController extends StateNotifier<AsyncValue<bool?>> {
  final EventRepositoryInterface _repository;
  RedactEventController(this._repository) : super(const AsyncValue.data(null));

  /// Redact Calendar event.
  Future<void> redact(
    String spaceId,
    String eventId,
    String? reason,
  ) async {
    EasyLoading.show(status: 'Removing Calendar Event', dismissOnTap: false);
    state = const AsyncValue.loading();
    final res = await _repository.redactCalendarEvent(
      spaceId,
      eventId,
      reason,
    );
    state = res.fold((l) {
      EasyLoading.showError('Error removing calendar event: $l');
      return AsyncError(l, StackTrace.current);
    }, (r) {
      EasyLoading.dismiss();
      return AsyncData(r);
    });
  }
}
