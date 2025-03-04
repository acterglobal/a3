import 'package:acter/common/actions/show_limited_space_list.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::visibility::chip');

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
    final visibilityLoader = ref.watch(roomVisibilityProvider(roomId));
    return visibilityLoader.when(
      data:
          (visibility) => GestureDetector(
            onTap: () {
              if (visibility != RoomVisibility.SpaceVisible) return;
              showLimitedSpaceList(context, roomId);
            },
            child: renderSpaceChip(context, visibility),
          ),
      error: (e, s) {
        _log.severe('Failed to load room visibility', e, s);
        return Chip(label: Text(L10n.of(context).loadingFailed(e)));
      },
      loading: () => renderLoading(),
    );
  }

  Widget renderLoading() {
    return Skeletonizer(
      child: SizedBox(
        width: 100,
        child: Chip(avatar: const Icon(Icons.language), label: Text(roomId)),
      ),
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
          avatar: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          label: Text(label, style: Theme.of(context).textTheme.labelSmall),
        );
  }
}
