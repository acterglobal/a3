import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        if (item.spaceProfileData.displayName!.toLowerCase().startsWith(data)) {
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
