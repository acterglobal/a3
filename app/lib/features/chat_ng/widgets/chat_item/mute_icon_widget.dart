import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat-item::mute-icon-widget');

class MuteIconWidget extends ConsumerWidget {
  final String roomId;

  const MuteIconWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMutedProvider = ref.watch(roomIsMutedProvider(roomId));

    return isMutedProvider.when(
      data: (isMuted) => _renderMuted(context, isMuted),
      error: (e, s) {
        _log.severe('Failed to load isMuted', e, s);
        return const SizedBox.shrink();
      },
      loading: () => Skeletonizer(child: _renderMuted(context, true)),
    );
  }

  Widget _renderMuted(BuildContext context, bool isMuted) {
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
}
