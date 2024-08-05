import 'package:acter/features/bookmarks/actions/bookmarking.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookmarkAction extends ConsumerWidget {
  final String type;
  final String id;
  const BookmarkAction({
    super.key,
    required this.type,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(isBookmarkedProvider((type: type, id: id)));

    if (isBookmarked) {
      return IconButton(
        onPressed: () => unbookmark(ref: ref, key: type, id: id),
        icon: const Icon(Icons.bookmark),
      );
    }

    return IconButton(
      icon: const Icon(Icons.bookmark_border),
      onPressed: () async => bookmark(id: id, ref: ref, key: type),
    );
  }
}
