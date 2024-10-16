/// Helpers to unwrap and work with nullable types
extension OptionExtension<T> on T? {
  /// if the value is not null, apply the function and return the result
  /// return null otherwise
  R? map<R>(R? Function(T) op, {R? defaultValue}) {
    final T? value = this;
    return value == null ? defaultValue : op(value);
  }

  /// if the value is not null apply the given async function and return
  /// the result
  Future<R?> mapAsync<R>(R? Function(T) op, {R? defaultValue}) async {
    final T? value = this;
    return value == null ? defaultValue : op(value);
  }
}
