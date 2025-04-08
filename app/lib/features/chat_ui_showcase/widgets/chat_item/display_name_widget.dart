import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisplayNameWidget extends ConsumerWidget {
  final String roomId;
  final String? mockDisplayName;
  final TextStyle? style;

  const DisplayNameWidget({
    super.key,
    required this.roomId,
    this.mockDisplayName,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = mockDisplayName ?? _getDisplayName(ref);

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
