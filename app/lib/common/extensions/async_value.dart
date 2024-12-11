import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueAsFuture on AsyncValue {
  Future<S> asFuture<S, T>([S Function(T)? mapper]) => map(
        data: (d) =>
            Future.value(mapper != null ? mapper(d.requireValue) : d.value),
        error: (e) => Future.error(e.error),
        loading: (l) => Completer<S>().future,
      );
}
