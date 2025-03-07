import 'package:acter/features/bookmarks/actions/bookmarking.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookmarkAction extends ConsumerWidget {
  final Bookmarker bookmarker;
  const BookmarkAction({super.key, required this.bookmarker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(isBookmarkedProvider(bookmarker));

    if (isBookmarked) {
      return IconButton(
        key: ValueKey('${bookmarker.id}-unbookmark'),
        onPressed: () => unbookmark(ref: ref, bookmarker: bookmarker),
        icon: const Icon(Icons.bookmark),
      );
    }

    return IconButton(
      key: ValueKey('${bookmarker.id}-bookmark'),
      icon: const Icon(Icons.bookmark_border),
      onPressed: () async => bookmark(ref: ref, bookmarker: bookmarker),
    );
  }
}
