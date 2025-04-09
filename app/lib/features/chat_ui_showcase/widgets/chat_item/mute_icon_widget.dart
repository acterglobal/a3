import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MuteIconWidget extends ConsumerWidget {
  final String roomId;

  const MuteIconWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = _isMuted(ref);

    if (!isMuted) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        PhosphorIcons.bellSlash(),
        size: 20,
        color: Theme.of(context).colorScheme.surfaceTint,
      ),
    );
  }

  bool _isMuted(WidgetRef ref) {
    final isMutedProvider = ref.watch(roomIsMutedProvider(roomId));
    return isMutedProvider.valueOrNull ?? false;
  }
}
