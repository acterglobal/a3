import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class VisibilityChip extends ConsumerWidget {
  final String roomId;

  const VisibilityChip({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceVisibility = ref.watch(roomVisibilityProvider(roomId));
    return spaceVisibility.when(
      data: (visibility) {
        return renderSpaceChip(context, visibility);
      },
      error: (error, st) => Chip(
        label: Text(L10n.of(context).loadingFailed(error)),
      ),
      loading: () => renderLoading(),
    );
  }

  Widget renderLoading() {
    return Skeletonizer(
      child: Chip(
        avatar: const Icon(Icons.language),
        label: Text(roomId),
      ),
    );
  }

  Widget renderSpaceChip(BuildContext context, RoomVisibility? visibility) {
    IconData icon = Icons.lock;
    String label = L10n.of(context).private;
    switch (visibility) {
      case RoomVisibility.Public:
        icon = Icons.language;
        label = L10n.of(context).public;
        break;
      case RoomVisibility.SpaceVisible:
        icon = Atlas.users;
        label = L10n.of(context).limited;
      default:
        break;
    }
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      backgroundColor: Theme.of(context).colorScheme.neutral,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        side: BorderSide(
          color: Theme.of(context).colorScheme.neutral3,
        ),
      ),
      avatar: Icon(
        icon,
        color: Theme.of(context).colorScheme.neutral5,
      ),
      label: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall!
            .copyWith(color: Theme.of(context).colorScheme.neutral5),
      ),
    );
  }
}
