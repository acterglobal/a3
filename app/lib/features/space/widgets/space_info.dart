import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/visibility/visibility_chip.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Wrap(
      children: [
        VisibilityChip(roomId: spaceId),
        const SizedBox(width: 5),
        Consumer(builder: acterSpaceInfoUI),
      ],
    );
  }

  Widget acterSpaceInfoUI(BuildContext context, WidgetRef ref, Widget? child) {
    final space = ref.watch(spaceProvider(spaceId)).valueOrNull;
    if (space != null) {
      final isActerSpace = ref.watch(isActerSpaceForSpace(space)).valueOrNull;
      if (isActerSpace == false) {
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
    }
    return const SizedBox.shrink();
  }
}
