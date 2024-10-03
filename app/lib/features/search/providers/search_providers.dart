import 'package:riverpod/riverpod.dart';

final searchValueProvider = StateProvider.autoDispose<String>((ref) => '');

//Search FILTERS
enum SearchFilters {
  all,
  spaces,
  pins,
  events,
  tasks,
}

final searchFilterProvider =
    StateProvider.autoDispose<SearchFilters>((ref) => SearchFilters.all);
