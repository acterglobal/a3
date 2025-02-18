import 'package:acter/common/providers/reactions_providers.dart';
import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter/features/news/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show NewsEntry, ReactionManager;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

final newsListProvider = AsyncNotifierProvider.family<AsyncNewsListNotifier,
    List<NewsEntry>, String?>(
  () => AsyncNewsListNotifier(),
);

final storyListProvider =
    AsyncNotifierProvider.family<AsyncNewsListNotifier, List<Story>, String?>(
  () => AsyncStoryListNotifier(),
);

final updatesProvider =
    FutureProvider.family<List<UpdateEntry>, String?>((ref, arg) async {
  final news = (await ref.watch(newsListProvider(arg).future))
      .map((inner) => UpdateNewsEntry(inner))
      .toList();
  final stories = (await ref.watch(storyListProvider(arg).future))
      .map((inner) => UpdateStory(inner))
      .toList();

  final List<UpdateEntry> entries = [];
  entries.addAll(news);
  entries.addAll(stories);

  // sort
  return entries;
});

final newsReactionsProvider =
    FutureProvider.family<ReactionManager, NewsEntry>((ref, news) async {
  final manager = await news.reactions();
  return ref.watch(reactionManagerProvider(manager));
});

final likedByMeProvider =
    FutureProvider.autoDispose.family<bool, NewsEntry>((ref, news) async {
  final reactionsManager = await ref.watch(newsReactionsProvider(news).future);
  return reactionsManager.likedByMe();
});

final totalLikesForNewsProvider =
    FutureProvider.autoDispose.family<int, NewsEntry>((ref, news) async {
  final reactionsManager = await ref.watch(newsReactionsProvider(news).future);
  return reactionsManager.likesCount();
});
