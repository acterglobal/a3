import 'package:acter/features/public_room_search/models/public_search_filters.dart';
import 'package:acter/features/public_room_search/providers/notifiers/public_search_filters_notifier.dart';
import 'package:acter/features/public_room_search/providers/notifiers/public_spaces_notifier.dart';
import 'package:acter/features/public_room_search/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

final publicSearchProvider = StateNotifierProvider.autoDispose<
  PublicSearchNotifier,
  PagedState<Next?, PublicSearchResultItem>
>((ref) {
  return PublicSearchNotifier(ref);
});

final searchFilterProvider =
    StateNotifierProvider<PublicSearchFiltersNotifier, PublicSearchFilters>(
      (ref) => PublicSearchFiltersNotifier(),
    );
