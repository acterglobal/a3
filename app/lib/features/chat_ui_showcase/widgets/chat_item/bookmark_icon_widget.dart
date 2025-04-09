import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookmarkIconWidget extends ConsumerWidget {
  final String roomId;

  const BookmarkIconWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarkedProvider = ref.watch(isConvoBookmarked(roomId));

    return isBookmarkedProvider.when(
      data: (isBookmarked) => _renderBookmarked(context, isBookmarked),
      error: (e, s) => const SizedBox.shrink(),
      loading: () => Skeletonizer(child: _renderBookmarked(context, false)),
    );
  }

  Widget _renderBookmarked(BuildContext context, bool isBookmarked) {
    if (!isBookmarked) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        PhosphorIcons.bookmarkSimple(),
        size: 20,
        color: Theme.of(context).colorScheme.surfaceTint,
      ),
    );
  }
}
