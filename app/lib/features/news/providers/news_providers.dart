import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter/features/news/providers/notifiers/post_update_notifier.dart';
import 'package:acter/features/news/providers/notifiers/search_space_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsListProvider =
    StateNotifierProvider<NewsListStateNotifier, AsyncValue<List<NewsEntry>>>(
  (ref) => NewsListStateNotifier(ref),
);

final postUpdateProvider =
    AutoDisposeAsyncNotifierProvider<PostUpdateNotifier, void>(
  () => PostUpdateNotifier(),
);

final searchSpaceProvider =
    StateNotifierProvider.autoDispose<SearchSpaceNotifier, List<SpaceItem>>(
  (ref) => SearchSpaceNotifier(ref, []),
);

final selectedSpaceProvider =
    StateProvider.autoDispose<SpaceItem?>((ref) => null);

final isSearchingProvider = StateProvider.autoDispose<bool>((ref) => false);
