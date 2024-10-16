// helper fn to mimic Option::map() in rust
// it is used to remove bang operator about nullable variable
extension Let<T> on T? {
  R? let<R>(R? Function(T) op) {
    final T? value = this;
    return value == null ? null : op(value);
  }

  // it supports async callback too unlike `extension_nullable`
  Future<R?> letAsync<R>(R? Function(T) op) async {
    final T? value = this;
    return value == null ? null : op(value);
  }
}
