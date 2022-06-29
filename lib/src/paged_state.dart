import 'dart:math';
import 'package:collection/collection.dart';

const undefined = Object();

// We can't use freezed here because otherwise the PagedState could not be extended

/// [PagedState] contains the state that is needed to render an infinite scroll list
/// This class can be extended to add more properties specific to particular use cases
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
        error: error == undefined 
            ? this.error 
            : error,
        nextPageKey: nextPageKey == undefined
            ? this.nextPageKey
            : nextPageKey as PageKeyType?,
        previousPageKeys: previousPageKeys ?? this.previousPageKeys);
  }

  @override
  String toString() {
    return 'PagedState(records: $records, error: $error, nextPageKey: $nextPageKey, previousPageKeys: $previousPageKeys)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PagedState &&
            const DeepCollectionEquality().equals(other.records, records) &&
            const DeepCollectionEquality().equals(other.error, e) &&
            const DeepCollectionEquality().equals(other.nextPageKey, nextPageKey) &&
            const DeepCollectionEquality().equals(other.previousPageKeys, previousPageKeys));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(records),
      const DeepCollectionEquality().hash(error),
      const DeepCollectionEquality().hash(nextPageKey),
      const DeepCollectionEquality().hash(previousPageKeys));
}
