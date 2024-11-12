import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<List<T>> priotizeBookmarked<T>(
  Ref ref,
  BookmarkType t,
  List<T> items, {
  required String Function(T) getId,
}) async {
  final bookmarks = await ref.watch(bookmarkByTypeProvider(t).future);
  if (bookmarks.isEmpty) {
    return items;
  }
  final remaining = List.of(items);
  final beginning = List<T>.empty(growable: true);
  for (final b in bookmarks) {
    for (final (idx, item) in remaining.indexed) {
      if (getId(item) == b) {
        beginning.add(item);
        remaining.removeAt(idx);
        break;
      }
    }
  }

  return beginning.followedBy(remaining).toList();
}
