import 'package:flutter_riverpod/flutter_riverpod.dart';

// A State Provider that given a ref and and provider will
// listen to the provider and compare the inner async value
// to the last one that was given - ignoring in between reload and refreshing -
// and only if it is different will it actually update the internal
// state.
class CachedAsyncStateProvider<T> extends StateNotifier<AsyncValue<T>> {
  final ProviderBase<AsyncValue<T>> _provider;
  CachedAsyncStateProvider(this._provider, Ref ref, [T? startValue])
      : super(
          startValue != null ? AsyncData(startValue) : AsyncValue<T>.loading(),
        ) {
    ref.listen(this._provider, (prev, next) {
      if (next.isRefreshing || next.isReloading) {
        return;
      }

      if (next.hasValue) {
        if (state.valueOrNull != next.valueOrNull) {
          state = next;
        }
      } else if (next.hasError) {
        if (state.error != next.error) {
          state = next;
        }
      }
    });
  }
}
