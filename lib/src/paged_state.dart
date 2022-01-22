const undefined = Object();

class PagedState<PageKeyType, ItemType> {
  final List<ItemType>? records;
  final dynamic error;
  final PageKeyType? nextPageKey;
  const PagedState({this.records, this.error, this.nextPageKey});

  PagedState<PageKeyType, ItemType> copyWith(
      {List<ItemType>? records,
      dynamic error,
      dynamic nextPageKey = undefined}) {
    return PagedState<PageKeyType, ItemType>(
        records: records ?? this.records,
        error: error ?? this.error,
        nextPageKey: nextPageKey == undefined
            ? this.nextPageKey
            : nextPageKey as PageKeyType?);
  }
}
