import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchSpaceProvider =
    StateNotifierProvider.autoDispose<SearchSpaceNotifier, List<SpaceItem>>(
  (ref) => SearchSpaceNotifier(ref, []),
);

final selectedSpaceProvider =
    StateProvider.autoDispose<SpaceItem?>((ref) => null);

final isSearchingProvider = StateProvider.autoDispose<bool>((ref) => false);

class SearchSpaceNotifier extends StateNotifier<List<SpaceItem>> {
  final Ref ref;
  List<SpaceItem> items;

  SearchSpaceNotifier(this.ref, this.items) : super([]) {
    _init();
  }

  void _init() async {
    final data = await ref.read(spaceItemsProvider.future);
    items = data;
    state = items;
  }

  void filterSpace(String value) {
    state = [];
    String data = value.trim().toLowerCase();
    if (value.isNotEmpty) {
      for (var item in items) {
        if (item.displayName!.toLowerCase().startsWith(data)) {
          state = [...state, item];
          ref.read(isSearchingProvider.notifier).update((state) => true);
        }
      }
    } else {
      state = items;
      ref.read(isSearchingProvider.notifier).update((state) => false);
    }
  }
}
