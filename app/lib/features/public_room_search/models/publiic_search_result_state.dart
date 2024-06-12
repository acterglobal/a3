import 'package:acter/features/public_room_search/models/public_search_filters.dart';
import 'package:acter/features/public_room_search/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class PublicSearchResultState
    extends PagedState<Next?, PublicSearchResultItem> {
  // We can extends [PagedState] to add custom parameters to our state
  final PublicSearchFilters filter;
  final bool loading;

  const PublicSearchResultState({
    super.records,
    String? super.error,
    super.nextPageKey = const Next(isStart: true),
    List<Next?>? previousPageKeys,
    required this.filter,
    this.loading = false,
  });

  @override
  PublicSearchResultState copyWith({
    List<PublicSearchResultItem>? records,
    dynamic error,
    dynamic nextPageKey,
    PublicSearchFilters? filter,
    List<Next?>? previousPageKeys,
    bool? loading,
  }) {
    final sup = super.copyWith(
      records: records,
      error: error,
      nextPageKey: nextPageKey,
      previousPageKeys: previousPageKeys,
    );
    return PublicSearchResultState(
      records: sup.records,
      error: sup.error,
      nextPageKey: sup.nextPageKey,
      previousPageKeys: sup.previousPageKeys,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
    );
  }
}
