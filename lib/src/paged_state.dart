const undefined = Object();

class PagedState<PageKeyType, ItemType> {
  final List<ItemType>? records;
  final dynamic error;
  final PageKeyType? nextPageKey;
  final List<PageKeyType> previousPageKeys;
  const PagedState(
      {this.records,
      this.error,
      this.nextPageKey,
      this.previousPageKeys = const []});

  PagedState<PageKeyType, ItemType> copyWith(
      {List<ItemType>? records,
      dynamic error,
      dynamic nextPageKey = undefined,
      List<PageKeyType>? previousPageKeys}) {
    return PagedState<PageKeyType, ItemType>(
        records: records ?? this.records,
        error: error ?? this.error,
        nextPageKey: nextPageKey == undefined
            ? this.nextPageKey
            : nextPageKey as PageKeyType?,
        previousPageKeys: previousPageKeys ?? this.previousPageKeys);
  }
}
