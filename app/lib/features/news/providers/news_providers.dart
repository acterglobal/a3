import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter/features/news/providers/notifiers/reaction_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show NewsEntry, ReactionManager, Reaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsListProvider =
    AsyncNotifierProvider.autoDispose<AsyncNewsListNotifier, List<NewsEntry>>(
  () => AsyncNewsListNotifier(),
);

final newsReactionsProvider = FutureProvider.autoDispose
    .family<ReactionManager, NewsEntry>((ref, news) async {
  final manager = await news.reactions();
  return manager;
});

final reactionEntriesProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncNewsReactionsNotifier, List<Reaction>, NewsEntry>(
  () => AsyncNewsReactionsNotifier(),
);

final likedByMeProvider =
    FutureProvider.autoDispose.family<bool, NewsEntry>((ref, news) async {
  final manager = await news.reactions();
  return await manager.likedByMe();
});

final unlikedByMeProvider =
    FutureProvider.autoDispose.family<bool, NewsEntry>((ref, news) async {
  final manager = await news.reactions();
  return await manager.unlikedByMe();
});

final reactedByMeProvider =
    FutureProvider.autoDispose.family<bool, NewsEntry>((ref, news) async {
  final manager = await news.reactions();
  return await manager.reactedByMe();
});
