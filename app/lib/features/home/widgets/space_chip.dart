import 'package:flutter/material.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceChip extends ConsumerWidget {
  final SpaceItem? space;
  final String? spaceId;
  const SpaceChip({Key? key, this.space, this.spaceId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget renderSpace(space) => Chip(
          avatar: ActerAvatar(
            mode: DisplayMode.Space,
            displayName: space.spaceProfileData.displayName,
            uniqueId: space.roomId,
            avatar: space.spaceProfileData.getAvatarImage(),
            size: 24,
          ),
          label: Text(space.spaceProfileData.displayName ?? space.roomId),
        );
    if (space == null) {
      if (spaceId == null) {
        throw 'space or spaceId must be provided';
      }
      return ref.watch(briefSpaceItemProvider(spaceId!)).when(
            data: (space) => renderSpace(space),
            error: (error, st) => Chip(label: Text('Loading failed: $error')),
            loading: () => const Chip(
              label: Text('loading'),
            ),
          );
    }
    return renderSpace(space!);
  }
}
