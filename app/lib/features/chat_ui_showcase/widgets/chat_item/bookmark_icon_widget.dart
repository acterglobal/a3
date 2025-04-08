import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BookmarkIconWidget extends ConsumerWidget {
  final String roomId;
  final bool? mockIsBookmarked;

  const BookmarkIconWidget({
    super.key,
    required this.roomId,
    this.mockIsBookmarked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = mockIsBookmarked ?? _isBookmarked(ref);

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

  bool _isBookmarked(WidgetRef ref) {
    final isBookmarkedProvider = ref.watch(isConvoBookmarked(roomId));
    return isBookmarkedProvider.valueOrNull ?? false;
  }
}
