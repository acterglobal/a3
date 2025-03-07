import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/bookmarks/providers/notifiers.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarksManagerProvider =
    AsyncNotifierProvider<BookmarksManagerNotifier, Bookmarks>(
      () => BookmarksManagerNotifier(),
    );

final bookmarkByTypeProvider =
    FutureProvider.family<List<String>, BookmarkType>((ref, type) async {
      final bookmarks = await ref.watch(bookmarksManagerProvider.future);
      return asDartStringList(bookmarks.entries(type.name));
    });

final isBookmarkedProvider = StateProvider.family<bool, Bookmarker>((
  ref,
  bookmarker,
) {
  final bookmarks =
      ref.watch(bookmarkByTypeProvider(bookmarker.type)).valueOrNull ?? [];
  return bookmarks.contains(bookmarker.id);
});
