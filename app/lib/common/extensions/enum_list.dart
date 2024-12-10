import 'dart:collection';

/// A list wrapper around lists of enum
/// so that comparing them will actually
/// check the inner enum items.
class EnumList<T extends Enum> extends ListBase<T> {
  final List<T> entries;
  const EnumList({this.entries = const []});

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
    if (other is! EnumList<T>) {
      return false;
    }
    if (length != other.length) {
      return false;
    }

    for (var i = 0; i < length; i++) {
      if (this[i].index != other[i].index) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => entries.hashCode;
}
