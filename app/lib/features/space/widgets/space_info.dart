import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/visibility/visibility_chip.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::space_info');

final isActerSpaceForSpace =
    FutureProvider.autoDispose.family<bool, Space>((ref, space) async {
  return await space.isActerSpace();
});

class SpaceInfo extends ConsumerWidget {
  final String spaceId;
  final double size;

  const SpaceInfo({
    super.key,
    this.size = 16,
    required this.spaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceLoader = ref.watch(spaceProvider(spaceId));
    return spaceLoader.when(
      data: (space) => Wrap(
        children: [
          VisibilityChip(roomId: spaceId),
          const SizedBox(width: 5),
          acterSpaceInfoUI(context, ref, space),
        ],
      ),
      error: (e, s) {
        _log.severe('Failed to load space', e, s);
        return Text(L10n.of(context).loadingFailed(e));
      },
      loading: () => skeletonUI(),
    );
  }

  Widget skeletonUI() {
    return Skeletonizer(
      child: Row(
        children: [
          Icon(
            Atlas.glasses_vision_thin,
            size: size,
          ),
          Icon(
            Atlas.lock_clipboard_thin,
            size: size,
          ),
          Icon(
            Atlas.shield_exclamation_thin,
            size: size,
          ),
        ],
      ),
    );
  }

  Widget acterSpaceInfoUI(BuildContext context, WidgetRef ref, Space space) {
    if (ref.watch(isActerSpaceForSpace(space)).valueOrNull != true) {
      return Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Tooltip(
          message: L10n.of(context).thisIsNotAProperActerSpace,
          child: Icon(
            Atlas.triangle_exclamation_thin,
            size: size,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
