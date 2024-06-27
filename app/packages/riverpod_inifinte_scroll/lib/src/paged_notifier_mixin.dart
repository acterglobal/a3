import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_infinite_scroll/src/paged_state.dart';

/// [PagedNotifierMixin] is a mixin that ensure the StateNotifier will implement the right load method
mixin PagedNotifierMixin<PageKeyType, ItemType,
    State extends PagedState<PageKeyType, ItemType>> on StateNotifier<State> {
  Future<List<ItemType>?> load(PageKeyType page, int limit);
}
