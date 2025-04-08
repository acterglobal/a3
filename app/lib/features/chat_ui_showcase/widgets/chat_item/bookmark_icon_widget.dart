import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BookmarkIconWidget extends ConsumerWidget {
  final String roomId;
  const BookmarkIconWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarkedProvider = ref.watch(isConvoBookmarked(roomId));
    final isBookmarked = isBookmarkedProvider.valueOrNull ?? false;

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
