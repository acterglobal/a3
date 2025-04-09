import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DisplayNameWidget extends ConsumerWidget {
  final String roomId;
  final TextStyle? style;

  const DisplayNameWidget({super.key, required this.roomId, this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayNameProvider = ref.watch(roomDisplayNameProvider(roomId));
    return displayNameProvider.when(
      data: (displayName) => _renderDisplayName(context, displayName),
      error: (e, s) => const SizedBox.shrink(),
      loading:
          () =>
              Skeletonizer(child: _renderDisplayName(context, 'Display Name')),
    );
  }

  Widget _renderDisplayName(BuildContext context, String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
