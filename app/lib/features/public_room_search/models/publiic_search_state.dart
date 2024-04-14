import 'package:acter/features/public_room_search/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class PublicSearchState extends PagedState<Next?, PublicSearchResultItem> {
  // We can extends [PagedState] to add custom parameters to our state
  final String? server;
  final String? searchValue;

  const PublicSearchState({
    super.records,
    String? super.error,
    super.nextPageKey = const Next(isStart: true),
    List<Next?>? previousPageKeys,
    this.server,
    this.searchValue,
  });

  @override
  PublicSearchState copyWith({
    List<PublicSearchResultItem>? records,
    dynamic error,
    dynamic nextPageKey,
    String? server,
    String? searchValue,
    List<Next?>? previousPageKeys,
  }) {
    final sup = super.copyWith(
      records: records,
      error: error,
      nextPageKey: nextPageKey,
      previousPageKeys: previousPageKeys,
    );
    return PublicSearchState(
      records: sup.records,
      error: sup.error,
      nextPageKey: sup.nextPageKey,
      previousPageKeys: sup.previousPageKeys,
      server: server,
      searchValue: searchValue,
    );
  }
}
