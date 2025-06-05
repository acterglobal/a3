import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/notifiers/event_location_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show EventLocationInfo;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventDraftLocationsProvider =
    StateNotifierProvider<EventDraftLocationsNotifier, List<EventLocationDraft>>(
  (ref) => EventDraftLocationsNotifier(),
);

// Provider for all event locations
final asyncEventLocationsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncEventLocationsNotifier, List<EventLocationInfo>, String>(
  () => AsyncEventLocationsNotifier(),
);