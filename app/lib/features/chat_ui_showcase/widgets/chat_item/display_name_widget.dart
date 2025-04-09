import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisplayNameWidget extends ConsumerWidget {
  final String roomId;
  final TextStyle? style;

  const DisplayNameWidget({super.key, required this.roomId, this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = _getDisplayName(ref);

    if (displayName.isEmpty) return const SizedBox.shrink();

    return Text(
      displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }

  String _getDisplayName(WidgetRef ref) {
    final displayNameProvider = ref.watch(roomDisplayNameProvider(roomId));
    return displayNameProvider.valueOrNull ?? roomId;
  }
}
