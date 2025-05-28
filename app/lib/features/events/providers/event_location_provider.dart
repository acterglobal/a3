import 'package:acter/features/events/model/event_location_model.dart';
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