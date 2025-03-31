import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/room/join_rule/join_rule_chip.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceInfo extends ConsumerWidget {
  final String spaceId;
  final double size;

  const SpaceInfo({super.key, this.size = 16, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    children: [
      JoinRuleChip(roomId: spaceId),
      const SizedBox(width: 5),
      if (ref.watch(isActerSpace(spaceId)).valueOrNull != true)
        acterSpaceInfoUI(context, ref),
    ],
  );

  Widget acterSpaceInfoUI(BuildContext context, WidgetRef ref) => Padding(
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
