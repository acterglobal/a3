import 'package:acter/common/actions/show_limited_space_list.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VisibilityChip extends ConsumerWidget {
  final String roomId;
  final bool useCompactView;

  const VisibilityChip({
    super.key,
    required this.roomId,
    this.useCompactView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(roomVisibilityProvider(roomId));
    return GestureDetector(
      onTap: () {
        if (visibility != RoomVisibility.SpaceVisible) return;
        showLimitedSpaceList(context, roomId);
      },
      child: renderSpaceChip(context, visibility),
    );
  }

  Widget renderSpaceChip(BuildContext context, RoomVisibility? visibility) {
    final lang = L10n.of(context);
    IconData icon = switch (visibility) {
      RoomVisibility.Public => Icons.language,
      RoomVisibility.SpaceVisible => Atlas.users,
      _ => Icons.lock,
    };
    String label = switch (visibility) {
      RoomVisibility.Public => lang.public,
      RoomVisibility.SpaceVisible => lang.limited,
      _ => lang.private,
    };
    return useCompactView
        ? Text(label, style: Theme.of(context).textTheme.labelSmall)
        : Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            label: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          );
  }
}
