import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoomMuteIconWidget extends ConsumerWidget {
  final String roomId;
  const RoomMuteIconWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMutedProvider = ref.watch(roomIsMutedProvider(roomId));
    final isMuted = isMutedProvider.valueOrNull ?? false;

    if (!isMuted) return const SizedBox.shrink();

    return Icon(
      PhosphorIcons.bellSlash(),
      size: 20,
      color: Theme.of(context).colorScheme.surfaceTint,
    );
  }
}
