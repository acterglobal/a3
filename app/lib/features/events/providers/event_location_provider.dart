import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/notifiers/event_location_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show EventLocationInfo;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventLocationsNotifier extends StateNotifier<List<EventLocationDraft>> {
  EventLocationsNotifier() : super([]);

  void addLocation(EventLocationDraft location) {
    state = [...state, location];
  }

  void removeLocation(EventLocationDraft location) {
    state = state.where((loc) => loc != location).toList();
  }

  void clearLocations() {
    state = [];
  }
}

final eventLocationsProvider =
    StateNotifierProvider<EventLocationsNotifier, List<EventLocationDraft>>(
  (ref) => EventLocationsNotifier(),
);

// Provider for all event locations
final asyncEventLocationsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncEventLocationsNotifier, List<EventLocationInfo>, String>(
  () => AsyncEventLocationsNotifier(),
);

// Provider for physical event locations
final asyncPhysicalEventLocationsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncPhysicalEventLocationsNotifier, List<EventLocationInfo>, String>(
  () => AsyncPhysicalEventLocationsNotifier(),
);

// Provider for virtual event locations
final asyncVirtualEventLocationsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncVirtualEventLocationsNotifier, List<EventLocationInfo>, String>(
  () => AsyncVirtualEventLocationsNotifier(),
); 