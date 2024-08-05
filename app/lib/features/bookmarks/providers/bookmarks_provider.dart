import 'package:acter/features/bookmarks/providers/notifiers.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarksManagerProvider =
    AsyncNotifierProvider<BookmarksManagerNotifier, Bookmarks>(
  () => BookmarksManagerNotifier(),
);

final bookmarkByKeyProvider =
    FutureProvider.family<List<String>, String>((ref, key) async {
  final bookmarks = await ref.watch(bookmarksManagerProvider.future);
  return (bookmarks.entries(key)).map((s) => s.toDartString()).toList();
});

final isBookmarkedProvider =
    StateProvider.family<bool, Bookmarker>((ref, query) {
  final bookmarks =
      ref.watch(bookmarkByKeyProvider(query.type)).valueOrNull ?? [];
  return bookmarks.contains(query.id);
});
