import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show NewsEntry, ReactionManager, Reaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsListProvider =
    AsyncNotifierProvider.autoDispose<AsyncNewsListNotifier, List<NewsEntry>>(
  () => AsyncNewsListNotifier(),
);

final newsReactionManagerProvider = FutureProvider.autoDispose
    .family<ReactionManager, NewsEntry>((ref, news) async {
  final manager = await news.reactionManager();
  return manager;
});

final myReactionStatusProvider =
    FutureProvider.autoDispose.family<bool, NewsEntry>((ref, news) async {
  final manager = await ref.watch(newsReactionManagerProvider(news).future);
  return await manager.myStatus();
});

final reactionsProvider = FutureProvider.autoDispose
    .family<List<Reaction>, NewsEntry>((ref, news) async {
  final manager = await ref.watch(newsReactionManagerProvider(news).future);
  return await manager.reactionEntries().then((ffiList) => ffiList.toList());
});
