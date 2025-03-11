import 'package:acter/common/providers/reactions_providers.dart';
import 'package:acter/features/news/model/type/update_entry.dart';
import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter/features/news/providers/notifiers/story_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show NewsEntry, ReactionManager, Story;
import 'package:riverpod/riverpod.dart';

//EVENT FILTERS
enum UpdateFilters { all, news, story }

final updateFilterProvider = StateProvider.autoDispose<UpdateFilters>(
  (ref) => UpdateFilters.all,
);

final newsListProvider = AsyncNotifierProvider.family<
  AsyncNewsListNotifier,
  List<NewsEntry>,
  String?
>(() => AsyncNewsListNotifier());

final newsUpdateListProvider =
    FutureProvider.family<List<UpdateEntry>, String?>((ref, arg) async {
      final news =
          (await ref.watch(
            newsListProvider(arg).future,
          )).map((inner) => UpdateNewsEntry(inner)).toList();
      return news;
    });

final storiesListProvider =
    AsyncNotifierProvider.family<AsyncStoryListNotifier, List<Story>, String?>(
      () => AsyncStoryListNotifier(),
    );

final storyUpdateListProvider =
    FutureProvider.family<List<UpdateEntry>, String?>((ref, arg) async {
      final stories =
          (await ref.watch(
            storiesListProvider(arg).future,
          )).map((inner) => UpdateStoryEntry(inner)).toList();
      return stories;
    });

final updateListProvider = FutureProvider.family<List<UpdateEntry>, String?>((
  ref,
  arg,
) async {
  final news = await ref.watch(newsUpdateListProvider(arg).future);
  final stories = await ref.watch(storyUpdateListProvider(arg).future);

  final List<UpdateEntry> entries = [];
  entries.addAll(stories);
  entries.addAll(news);

  entries.sort((a, b) => b.originServerTs().compareTo(a.originServerTs()));

  return entries;
});

final filteredUpdateListProvider = FutureProvider.family<
  List<UpdateEntry>,
  String?
>((ref, arg) async {
  final updateFilter = ref.watch(updateFilterProvider);

  return switch (updateFilter) {
    UpdateFilters.all => await ref.watch(updateListProvider(arg).future),
    UpdateFilters.news => await ref.watch(newsUpdateListProvider(arg).future),
    UpdateFilters.story => await ref.watch(storyUpdateListProvider(arg).future),
  };
});

final updateReactionsProvider =
    FutureProvider.family<ReactionManager, UpdateEntry>((ref, news) async {
      final manager = await news.reactions();
      return ref.watch(reactionManagerProvider(manager));
    });

final likedByMeProvider = FutureProvider.autoDispose.family<bool, UpdateEntry>((
  ref,
  news,
) async {
  final reactionsManager = await ref.watch(
    updateReactionsProvider(news).future,
  );
  return reactionsManager.likedByMe();
});

final totalLikesForNewsProvider = FutureProvider.autoDispose
    .family<int, UpdateEntry>((ref, news) async {
      final reactionsManager = await ref.watch(
        updateReactionsProvider(news).future,
      );
      return reactionsManager.likesCount();
    });
