import 'dart:async';

typedef OrElse<R> = R? Function();
typedef AsyncOrElse<R> = FutureOr<R?>? Function();

/// Helpers to unwrap and work with nullable types
extension OptionExtension<T> on T? {
  /// if the value is not null, apply the function and return the result
  /// return null otherwise
  R? map<R>(R? Function(T) op, {R? defaultValue, OrElse<R>? orElse}) {
    final T? value = this;
    return value == null ? defaultValue ?? orElse?.call() : op(value);
  }

  /// if the value is not null apply the given async function and return
  /// the result
  Future<R?> mapAsync<R>(
    Future<R?> Function(T) op, {
    R? defaultValue,
    AsyncOrElse<R>? orElse,
  }) async {
    final T? value = this;
    return value == null ? defaultValue ?? (await orElse?.call()) : op(value);
  }

  /// Unwrap the value or throw the `error`
  T expect([Object error = 'Value was null']) {
    final T? value = this;
    if (value == null) {
      throw error;
    }
    return value;
  }
}
