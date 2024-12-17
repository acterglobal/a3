import 'dart:collection';

/// A list wrapper around lists of enum
/// so that comparing them will actually
/// check the inner enum items.
class ComparableList<T> extends ListBase<T> {
  final List<T> entries;
  const ComparableList([this.entries = const []]);

  @override
  set length(int newLength) {
    entries.length = newLength;
  }

  @override
  int get length => entries.length;
  @override
  T operator [](int index) => entries[index];
  @override
  void operator []=(int index, T value) {
    entries[index] = value;
  }

  @override
  bool operator ==(Object other) {
    if (other is! ComparableList<T>) {
      return false;
    }
    if (length != other.length) {
      return false;
    }

    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => entries.hashCode;
}
