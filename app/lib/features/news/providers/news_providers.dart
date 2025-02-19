import 'package:acter/common/providers/reactions_providers.dart';
import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show NewsEntry, ReactionManager;
import 'package:riverpod/riverpod.dart';

final newsListProvider = AsyncNotifierProvider.family<AsyncNewsListNotifier,
    List<NewsEntry>, String?>(
  () => AsyncNewsListNotifier(),
);

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