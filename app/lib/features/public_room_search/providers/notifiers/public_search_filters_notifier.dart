import 'package:acter/features/public_room_search/models/public_search_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PublicSearchFiltersNotifier extends StateNotifier<PublicSearchFilters> {
  PublicSearchFiltersNotifier() : super(const PublicSearchFilters());

  void updateSearchTerm(String? newTerm) {
    state = state.copyWith(searchTerm: newTerm);
  }

  void updateSearchServer(String? server) {
    state = state.copyWith(server: server);
  }

  void updateFilters(FilterBy newFilter) {
    state = state.copyWith(filterBy: newFilter);
  }
}
