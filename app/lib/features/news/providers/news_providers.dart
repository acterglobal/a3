import 'package:acter/common/providers/reactions_providers.dart';
import 'package:acter/features/news/model/type/update_entry.dart';
import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter/features/news/providers/notifiers/story_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show NewsEntry, ReactionManager, Story;
import 'package:riverpod/riverpod.dart';

final newsListProvider = AsyncNotifierProvider.family<AsyncNewsListNotifier,
    List<NewsEntry>, String?>(
  () => AsyncNewsListNotifier(),
);
final storiesListProvider =
    AsyncNotifierProvider.family<AsyncStoryListNotifier, List<Story>, String?>(
  () => AsyncStoryListNotifier(),
);

final updateListProvider =
    FutureProvider.family<List<UpdateEntry>, String?>((ref, arg) async {
  final news = (await ref.watch(newsListProvider(arg).future))
      .map((inner) => UpdateNewsEntry(inner))
      .toList();
  final stories = (await ref.watch(storiesListProvider(arg).future))
      .map((inner) => UpdateStoryEntry(inner))
      .toList();

  final List<UpdateEntry> entries = [];
  entries.addAll(news);
  entries.addAll(stories);

  // sort
  return entries;
});

final updateReactionsProvider =
    FutureProvider.family<ReactionManager, UpdateEntry>((ref, news) async {
  final manager = await news.reactions();
  return ref.watch(reactionManagerProvider(manager));
});

final likedByMeProvider =
    FutureProvider.autoDispose.family<bool, UpdateEntry>((ref, news) async {
  final reactionsManager =
      await ref.watch(updateReactionsProvider(news).future);
  return reactionsManager.likedByMe();
});

final totalLikesForNewsProvider =
    FutureProvider.autoDispose.family<int, UpdateEntry>((ref, news) async {
  final reactionsManager =
      await ref.watch(updateReactionsProvider(news).future);
  return reactionsManager.likesCount();
});
