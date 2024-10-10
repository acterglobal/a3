import 'package:riverpod/riverpod.dart';

//Search FILTERS
enum SearchFilters {
  all,
  spaces,
  pins,
}

final searchFilterProvider =
    StateProvider.autoDispose<SearchFilters>((ref) => SearchFilters.all);
